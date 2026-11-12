from django.db import transaction
from rest_framework.exceptions import ValidationError
from apps.flocks.models import Flock
from .models import Observation

@transaction.atomic
def record_observation(*, flock_id, data) -> Observation:
    flock = Flock.objects.select_for_update().get(id=flock_id)
    
    if flock.status == Flock.Status.CLOSED:
        raise ValidationError({"flock": "Impossible de rajouter une observation sur un lot clôturé."})

    observation = Observation.objects.create(flock=flock, **data)
    
    from apps.health.tasks import analyze_flock
    analyze_flock.delay(str(flock.id))
    
    return observation
