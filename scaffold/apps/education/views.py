from rest_framework import viewsets, permissions
from .models import ContentCategory, EducationalContent
from .serializers import ContentCategorySerializer, EducationalContentSerializer


class ContentCategoryViewSet(viewsets.ReadOnlyModelViewSet):
    """Liste des catégories de contenus éducatifs (lecture seule)."""
    queryset = ContentCategory.objects.all()
    serializer_class = ContentCategorySerializer
    permission_classes = [permissions.IsAuthenticated]


class EducationalContentViewSet(viewsets.ReadOnlyModelViewSet):
    """Contenus éducatifs : lecture seule pour l'API mobile.
    La création/modification se fait via Django Admin.
    """
    queryset = EducationalContent.objects.select_related("category").order_by("-published_at")
    serializer_class = EducationalContentSerializer
    permission_classes = [permissions.IsAuthenticated]
