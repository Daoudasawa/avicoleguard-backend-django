from django.urls import path

app_name = "health"

urlpatterns = [
    # Health Analysis might not be exposed directly to users, or it can be a read-only endpoint.
    # We will leave it empty for now, as alerts are the primary interaction point.
]
