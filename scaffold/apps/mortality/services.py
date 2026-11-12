"""Logique métier mortalités — RM4 (verrou transactionnel) et RM11 (annulation tracée)."""
from django.db import transaction
from django.utils import timezone
from rest_framework.exceptions import ValidationError

from apps.flocks.models import Flock
from apps.audit.services import log_action
from .models import Mortality


@transaction.atomic
def record_mortality(*, flock_id, user, data: dict) -> Mortality:
    flock = Flock.objects.select_for_update().get(id=flock_id)   # verrou pessimiste — RM4

    if flock.status != Flock.Status.ACTIVE:
        raise ValidationError({"flock": "Ce lot est clôturé, aucune nouvelle saisie n'est acceptée."})  # RM7

    already_dead = flock.initial_count - flock.current_count
    if already_dead + data["dead_count"] > flock.initial_count:
        raise ValidationError({
            "dead_count": "La mortalité cumulée dépasserait l'effectif initial du lot.",
        })

    mortality = Mortality.objects.create(flock=flock, **data)
    flock.current_count -= data["dead_count"]
    flock.save(update_fields=["current_count"])

    # Déclenche l'analyse sanitaire de façon asynchrone (Celery) — voir apps/health
    from apps.health.tasks import analyze_flock
    analyze_flock.delay(str(flock.id))

    return mortality


@transaction.atomic
def cancel_mortality(*, mortality_id, user, reason: str) -> Mortality:
    mortality = Mortality.objects.select_related("flock").get(id=mortality_id)

    if mortality.cancelled_at is not None:
        raise ValidationError({"mortality": "Cette mortalité est déjà annulée."})

    flock = Flock.objects.select_for_update().get(id=mortality.flock_id)   # RM11 : recalcul sous verrou

    mortality.cancelled_at = timezone.now()
    mortality.cancel_reason = reason
    mortality.save(update_fields=["cancelled_at", "cancel_reason"])

    flock.current_count += mortality.dead_count
    flock.save(update_fields=["current_count"])

    log_action(
        user=user, action="mortality.cancelled",
        entity_type="mortality", entity_id=mortality.id,
        metadata={"reason": reason, "dead_count": mortality.dead_count},
    )

    return mortality
