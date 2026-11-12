from django.shortcuts import get_object_or_404
from rest_framework import viewsets, permissions
from apps.alerts.models import Alert
from .models import Recommendation
from .serializers import RecommendationSerializer


class RecommendationViewSet(viewsets.ModelViewSet):
    """
    Gestion des recommandations sanitaires sur une alerte.
    Sécurisation IDOR : consultation restreinte au propriétaire de la ferme
    (ou aux vétérinaires / techniciens assignés).
    """
    serializer_class = RecommendationSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        alert_id = self.kwargs.get("alert_pk")
        user = self.request.user

        qs = Recommendation.objects.filter(alert_id=alert_id).select_related("alert").order_by("-created_at")
        if user.role in ["veterinarian", "technician", "admin"]:
            return qs
        # Éleveur : ne peut voir que les recommandations de ses propres alertes
        return qs.filter(alert__flock__farm__owner=user)

    def perform_create(self, serializer):
        alert_id = self.kwargs.get("alert_pk")
        user = self.request.user

        if user.role in ["veterinarian", "technician", "admin"]:
            alert = get_object_or_404(Alert, id=alert_id)
        else:
            alert = get_object_or_404(Alert, id=alert_id, flock__farm__owner=user)

        is_pro = user.role in ["veterinarian", "technician"]

        serializer.save(
            alert=alert,
            generated_by=user.get_full_name() or user.email,
            validated_by_professional=is_pro,
        )
