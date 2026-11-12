from django.db import transaction
from rest_framework.exceptions import ValidationError
from apps.flocks.models import Flock
from .models import DailyMonitoring

@transaction.atomic
def record_daily_monitoring(*, flock_id, data) -> DailyMonitoring:
    flock = Flock.objects.select_for_update().get(id=flock_id)
    
    if flock.status == Flock.Status.CLOSED:
        raise ValidationError({"flock": "Impossible de rajouter un suivi sur un lot clôturé."})

    # Optional: ensure we don't have multiple monitorings for the same date unless handled by unique constraints?
    # Spec doesn't strictly say one per day, but implies it.
    if DailyMonitoring.active.filter(flock=flock, date=data["date"]).exists():
        raise ValidationError({"date": "Un suivi existe déjà pour cette date."})

    monitoring = DailyMonitoring.objects.create(flock=flock, **data)
    
    from apps.health.tasks import analyze_flock
    analyze_flock.delay(str(flock.id))
    
    return monitoring
