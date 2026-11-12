from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import TicketViewSet, TicketMessageViewSet

router = DefaultRouter()
router.register(r"tickets", TicketViewSet, basename="ticket")

app_name = "assistance"

urlpatterns = [
    path("", include(router.urls)),
    # Messages imbriqués sous un ticket
    path(
        "tickets/<uuid:ticket_pk>/messages/",
        TicketMessageViewSet.as_view({"get": "list", "post": "create"}),
        name="ticket-messages",
    ),
]
