from django.urls import path
from .views import SyncPullView, SyncPushView

app_name = "sync"

urlpatterns = [
    path('pull/', SyncPullView.as_view(), name='sync-pull'),
    path('push/', SyncPushView.as_view(), name='sync-push'),
]
