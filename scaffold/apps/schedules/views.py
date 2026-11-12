from rest_framework import viewsets, permissions
from .models import HealthSchedule
from .serializers import HealthScheduleSerializer


class HealthScheduleViewSet(viewsets.ModelViewSet):
    """
    CRUD du calendrier sanitaire.
    Isolation RM6 : consultation et modification strictement réservées
    au propriétaire du lot.
    """
    serializer_class = HealthScheduleSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        if user.role in ["veterinarian", "technician", "admin"]:
            return HealthSchedule.objects.all().select_related("flock__farm")
        return HealthSchedule.objects.filter(flock__farm__owner=user).select_related("flock__farm")
