from rest_framework import viewsets
from rest_framework.permissions import IsAuthenticated
from .models import DailyMonitoring
from .serializers import DailyMonitoringSerializer, DailyMonitoringCreateSerializer
from .permissions import IsFlockOwner
from .services import record_daily_monitoring

class DailyMonitoringViewSet(viewsets.ModelViewSet):
    permission_classes = [IsAuthenticated, IsFlockOwner]

    def get_queryset(self):
        flock_id = self.kwargs.get("flock_pk")
        return DailyMonitoring.active.filter(flock_id=flock_id)

    def get_serializer_class(self):
        if self.action == "create":
            return DailyMonitoringCreateSerializer
        return DailyMonitoringSerializer

    def perform_create(self, serializer):
        record_daily_monitoring(
            flock_id=self.kwargs["flock_pk"], 
            data=serializer.validated_data
        )
