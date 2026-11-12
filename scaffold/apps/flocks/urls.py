from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import FlockViewSet

app_name = "flocks"

router = DefaultRouter()
router.register(r"flocks", FlockViewSet, basename="flock")

urlpatterns = [
    path("", include(router.urls)),
]
