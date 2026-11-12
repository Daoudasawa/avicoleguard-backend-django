from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import HealthScheduleViewSet

router = DefaultRouter()
router.register(r"schedules", HealthScheduleViewSet, basename="health-schedule")

app_name = "schedules"

urlpatterns = [
    path("", include(router.urls)),
]
