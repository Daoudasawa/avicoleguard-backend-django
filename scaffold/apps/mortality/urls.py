from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import MortalityViewSet

app_name = "mortality"

router = DefaultRouter()
router.register(r"mortalities", MortalityViewSet, basename="mortality")

mortality_list = MortalityViewSet.as_view({
    "get": "list",
    "post": "create",
})
mortality_detail = MortalityViewSet.as_view({
    "get": "retrieve",
    "put": "update",
    "patch": "partial_update",
})
mortality_cancel = MortalityViewSet.as_view({
    "post": "cancel",
})

urlpatterns = [
    # Routes directes
    path("", include(router.urls)),
    # Routes imbriquées sous un lot
    path("flocks/<uuid:flock_pk>/mortalities/", mortality_list, name="flock-mortality-list"),
    path("flocks/<uuid:flock_pk>/mortalities/<uuid:pk>/", mortality_detail, name="flock-mortality-detail"),
    path("flocks/<uuid:flock_pk>/mortalities/<uuid:pk>/cancel/", mortality_cancel, name="flock-mortality-cancel"),
]
