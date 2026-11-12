from django.shortcuts import get_object_or_404
from rest_framework import viewsets, permissions, status
from rest_framework.decorators import action
from rest_framework.response import Response
from apps.flocks.models import Flock
from .models import Mortality
from .serializers import MortalitySerializer, MortalityCancelSerializer
from .services import record_mortality, cancel_mortality


class MortalityViewSet(viewsets.ModelViewSet):
    """
    Gestion des déclarations de mortalité.
    Délègue la logique métier sensible aux services RM4 / RM11.
    """
    queryset = Mortality.objects.none()
    serializer_class = MortalitySerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        qs = Mortality.objects.filter(flock__farm__owner=self.request.user)
        flock_pk = self.kwargs.get("flock_pk")
        if flock_pk:
            qs = qs.filter(flock_id=flock_pk)
        return qs.order_by("-date", "-created_at")

    def create(self, request, *args, **kwargs):
        flock_id = self.kwargs.get("flock_pk") or request.data.get("flock")
        if not flock_id:
            return Response(
                {"flock": "Le paramètre flock est obligatoire."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        # Vérification d'appartenance de la ferme/lot au demandeur (RM6)
        get_object_or_404(Flock, id=flock_id, farm__owner=request.user)

        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        # Délégation au service métier (verrou pessimiste RM4, mise à jour effectif, Celery)
        mortality = record_mortality(
            flock_id=flock_id,
            user=request.user,
            data=serializer.validated_data,
        )

        return Response(
            MortalitySerializer(mortality).data,
            status=status.HTTP_201_CREATED,
        )

    @action(detail=True, methods=["post"], url_path="cancel")
    def cancel(self, request, *args, **kwargs):
        """
        Annulation tracée d'une mortalité erronée (RM11).
        Réajuste l'effectif actuel du lot sous transaction atomique.
        """
        mortality = self.get_object()
        serializer = MortalityCancelSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        updated_mortality = cancel_mortality(
            mortality_id=mortality.id,
            user=request.user,
            reason=serializer.validated_data["reason"],
        )

        return Response(MortalitySerializer(updated_mortality).data)
