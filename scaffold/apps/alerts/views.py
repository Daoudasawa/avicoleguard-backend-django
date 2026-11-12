from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from .models import Alert
from .serializers import AlertSerializer
from .permissions import IsFlockOwnerOrVet
from apps.audit.services import log_action

class AlertViewSet(viewsets.ReadOnlyModelViewSet):
    serializer_class = AlertSerializer
    permission_classes = [IsAuthenticated, IsFlockOwnerOrVet]

    def get_queryset(self):
        flock_id = self.kwargs.get("flock_pk")
        return Alert.objects.filter(flock_id=flock_id).order_by("-created_at")

    @action(detail=True, methods=['post'])
    def acknowledge(self, request, flock_pk=None, pk=None):
        alert = self.get_object()
        if alert.status == Alert.Status.OPEN:
            alert.status = Alert.Status.ACKNOWLEDGED
            alert.save(update_fields=["status"])
            log_action(user=request.user, action="acknowledge_alert", entity_type="alert", entity_id=str(alert.id))
            return Response({"status": "Alert acknowledged"})
        return Response({"status": "Alert is not open"}, status=status.HTTP_400_BAD_REQUEST)
