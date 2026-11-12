from django.contrib import admin
from django.urls import path, include
from django.http import JsonResponse
from drf_spectacular.views import SpectacularAPIView, SpectacularSwaggerView


def health_check(request):
    return JsonResponse({"status": "ok"})


urlpatterns = [
    path("admin/", admin.site.urls),
    path("api/health/", health_check, name="health-check"),
    path("api/token/", include("rest_framework.urls", namespace="rest_framework")),

    path("api/schema/", SpectacularAPIView.as_view(), name="schema"),
    path("api/docs/", SpectacularSwaggerView.as_view(url_name="schema"), name="swagger-ui"),

    path("api/v1/auth/", include("apps.accounts.urls")),
    path("api/v1/", include("apps.farms.urls")),
    path("api/v1/", include("apps.flocks.urls")),
    path("api/v1/", include("apps.monitoring.urls")),
    path("api/v1/", include("apps.mortality.urls")),
    path("api/v1/", include("apps.observations.urls")),
    path("api/v1/", include("apps.health.urls")),
    path("api/v1/", include("apps.alerts.urls")),
    path("api/v1/", include("apps.recommendations.urls")),
    path("api/v1/", include("apps.schedules.urls")),
    path("api/v1/", include("apps.assistance.urls")),
    path("api/v1/", include("apps.education.urls")),
    path("api/v1/", include("apps.notifications.urls")),
    path("api/v1/sync/", include("apps.sync.urls")),
    path("api/v1/admin/", include("apps.audit.urls")),
]
