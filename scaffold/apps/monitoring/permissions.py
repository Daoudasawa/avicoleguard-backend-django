from rest_framework.permissions import BasePermission
from apps.flocks.models import Flock

class IsFlockOwner(BasePermission):
    def has_permission(self, request, view):
        try:
            flock = Flock.objects.select_related("farm").get(id=view.kwargs.get("flock_pk"))
            return flock.farm.owner_id == request.user.id
        except Flock.DoesNotExist:
            return False
