from django.urls import path
from .views import AlertViewSet

app_name = "alerts"

alert_list = AlertViewSet.as_view({'get': 'list'})
alert_detail = AlertViewSet.as_view({'get': 'retrieve'})
alert_ack = AlertViewSet.as_view({'post': 'acknowledge'})

urlpatterns = [
    path('flocks/<uuid:flock_pk>/alerts/', alert_list, name='alert-list'),
    path('flocks/<uuid:flock_pk>/alerts/<uuid:pk>/', alert_detail, name='alert-detail'),
    path('flocks/<uuid:flock_pk>/alerts/<uuid:pk>/acknowledge/', alert_ack, name='alert-acknowledge'),
]
