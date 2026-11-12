from django.urls import include, path
from rest_framework.routers import DefaultRouter
from .views import RecommendationViewSet

router = DefaultRouter()
router.register(r'alerts/(?P<alert_pk>[^/.]+)/recommendations', RecommendationViewSet, basename='alert-recommendations')

urlpatterns = [
    path('', include(router.urls)),
]
