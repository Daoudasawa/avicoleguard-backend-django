from django.utils import timezone
from django.db import transaction
from django.core.exceptions import ValidationError as DjangoValidationError
from rest_framework.exceptions import ValidationError
from apps.flocks.models import Flock
from apps.mortality.models import Mortality
from apps.monitoring.models import DailyMonitoring
from apps.observations.models import Observation
from .models import SynchronizationLog

def get_pull_data(user, last_sync_timestamp=None):
    """
    Récupère toutes les données modifiées depuis last_sync_timestamp pour l'éleveur.
    """
    # Pour le MVP, on filtre par propriétaire (Règle RM6)
    flocks_qs = Flock.objects.filter(farm__owner=user).select_related("farm")
    
    if last_sync_timestamp:
        flocks_qs = flocks_qs.filter(updated_at__gte=last_sync_timestamp)
        mortalities = Mortality.objects.filter(flock__farm__owner=user, created_at__gte=last_sync_timestamp).select_related("flock")
        monitorings = DailyMonitoring.objects.filter(flock__farm__owner=user, updated_at__gte=last_sync_timestamp).select_related("flock")
        observations = Observation.objects.filter(flock__farm__owner=user, updated_at__gte=last_sync_timestamp).select_related("flock")
    else:
        mortalities = Mortality.objects.filter(flock__farm__owner=user).select_related("flock")
        monitorings = DailyMonitoring.objects.filter(flock__farm__owner=user).select_related("flock")
        observations = Observation.objects.filter(flock__farm__owner=user).select_related("flock")

    # Convert to simple dict representations (in a real app, use serializers)
    data = {
        "flocks": list(flocks_qs.values()),
        "mortalities": list(mortalities.values()),
        "daily_monitorings": list(monitorings.values()),
        "observations": list(observations.values())
    }
    
    return data

@transaction.atomic
def process_push_data(user, data, device_id=""):
    """
    Traite le payload JSON (push) de façon idempotente (RM10).
    """
    sync_log = SynchronizationLog.objects.create(user=user, device_id=device_id)
    push_count = 0
    errors = {}

    try:
        # Traitement des mortalities
        if "mortalities" in data:
            for item in data["mortalities"]:
                try:
                    flock = Flock.objects.get(id=item["flock_id"], farm__owner=user)
                    Mortality.objects.update_or_create(
                        client_uuid=item["client_uuid"],
                        defaults={
                            "flock": flock,
                            "date": item["date"],
                            "dead_count": item["dead_count"],
                            "presumed_cause": item.get("presumed_cause", ""),
                            "notes": item.get("notes", ""),
                            "sync_status": "synced"
                        }
                    )
                    push_count += 1
                except Exception as e:
                    errors[item.get("client_uuid", "unknown")] = str(e)

        # Traitement des monitorings
        if "daily_monitorings" in data:
            for item in data["daily_monitorings"]:
                try:
                    flock = Flock.objects.get(id=item["flock_id"], farm__owner=user)
                    DailyMonitoring.objects.update_or_create(
                        client_uuid=item["client_uuid"],
                        defaults={
                            "flock": flock,
                            "date": item["date"],
                            "temperature": item.get("temperature"),
                            "water_consumption": item.get("water_consumption"),
                            "feed_consumption": item.get("feed_consumption"),
                            "average_weight": item.get("average_weight"),
                            "sync_status": "synced"
                        }
                    )
                    push_count += 1
                except Exception as e:
                    errors[item.get("client_uuid", "unknown")] = str(e)

        # Traitement des observations
        if "observations" in data:
            for item in data["observations"]:
                try:
                    flock = Flock.objects.get(id=item["flock_id"], farm__owner=user)
                    Observation.objects.update_or_create(
                        client_uuid=item["client_uuid"],
                        defaults={
                            "flock": flock,
                            "date": item["date"],
                            "type": item["type"],
                            "description": item.get("description", ""),
                            "sync_status": "synced"
                        }
                    )
                    push_count += 1
                except Exception as e:
                    errors[item.get("client_uuid", "unknown")] = str(e)
                    
        sync_log.push_count = push_count
        sync_log.errors = errors
        sync_log.completed_at = timezone.now()
        sync_log.status = SynchronizationLog.Status.SUCCESS if not errors else SynchronizationLog.Status.PARTIAL
        sync_log.save()
        
    except Exception as e:
        sync_log.completed_at = timezone.now()
        sync_log.status = SynchronizationLog.Status.FAILED
        sync_log.errors = {"global": str(e)}
        sync_log.save()
        raise e
        
    return sync_log
