from django.utils import timezone
from rest_framework import viewsets, permissions, status
from rest_framework.decorators import action
from rest_framework.response import Response
from .models import Flock
from .serializers import FlockSerializer


class FlockViewSet(viewsets.ModelViewSet):
    """
    CRUD complet des lots de volailles.
    Isolation RM6 : filtrage par fermes détenues par l'éleveur connecté.
    """
    queryset = Flock.objects.none()
    serializer_class = FlockSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return (
            Flock.objects.filter(farm__owner=self.request.user)
            .select_related("farm")
            .order_by("-arrival_date")
        )

    @action(detail=True, methods=["post"], url_path="close")
    def close(self, request, pk=None):
        """
        Clôture un lot (statut CLOSED) — RM7 : plus aucune saisie acceptée par la suite.
        """
        flock = self.get_object()
        if flock.status == Flock.Status.CLOSED:
            return Response(
                {"detail": "Ce lot est déjà clôturé."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        flock.status = Flock.Status.CLOSED
        if not flock.end_date:
            flock.end_date = timezone.now().date()
        flock.save(update_fields=["status", "end_date", "updated_at"])

        return Response(FlockSerializer(flock, context={"request": request}).data)
