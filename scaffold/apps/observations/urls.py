from django.urls import path
from .views import ObservationViewSet

app_name = "observations"

observation_list = ObservationViewSet.as_view({
    'get': 'list',
    'post': 'create'
})
observation_detail = ObservationViewSet.as_view({
    'get': 'retrieve',
    'put': 'update',
    'patch': 'partial_update'
})

urlpatterns = [
    path('flocks/<uuid:flock_pk>/observations/', observation_list, name='observation-list'),
    path('flocks/<uuid:flock_pk>/observations/<uuid:pk>/', observation_detail, name='observation-detail'),
]
