from rest_framework import viewsets, permissions
from .models import Farm
from .serializers import FarmSerializer


class FarmViewSet(viewsets.ModelViewSet):
    """
    CRUD complet des exploitations agricoles (Fermes).
    Isolation RM6 : chaque éleveur ne voit et ne gère que ses propres fermes.
    """
    queryset = Farm.objects.none()
    serializer_class = FarmSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return Farm.objects.filter(owner=self.request.user).order_by("-created_at")

    def perform_create(self, serializer):
        serializer.save(owner=self.request.user)
