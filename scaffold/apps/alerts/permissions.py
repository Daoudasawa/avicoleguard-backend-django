from rest_framework.permissions import BasePermission
from apps.flocks.models import Flock
from .models import Alert

class IsFlockOwnerOrVet(BasePermission):
    def has_permission(self, request, view):
        try:
            if "flock_pk" in view.kwargs:
                flock = Flock.objects.select_related("farm").get(id=view.kwargs.get("flock_pk"))
            elif "pk" in view.kwargs:
                alert = Alert.objects.select_related("flock__farm").get(id=view.kwargs.get("pk"))
                flock = alert.flock
            else:
                return False
            # MVP: For now we just check owner. Vet/Tech logic can be added later
            return flock.farm.owner_id == request.user.id
        except (Flock.DoesNotExist, Alert.DoesNotExist):
            return False
