from django.urls import path
from .views import DailyMonitoringViewSet

app_name = "monitoring"

monitoring_list = DailyMonitoringViewSet.as_view({
    'get': 'list',
    'post': 'create'
})
monitoring_detail = DailyMonitoringViewSet.as_view({
    'get': 'retrieve',
    'put': 'update',
    'patch': 'partial_update'
})

urlpatterns = [
    path('flocks/<uuid:flock_pk>/daily-monitorings/', monitoring_list, name='monitoring-list'),
    path('flocks/<uuid:flock_pk>/daily-monitorings/<uuid:pk>/', monitoring_detail, name='monitoring-detail'),
]
