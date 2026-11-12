from rest_framework import viewsets, permissions, status
from rest_framework.decorators import action
from rest_framework.response import Response
from .models import Ticket, TicketMessage
from .serializers import TicketSerializer, TicketMessageSerializer


class TicketViewSet(viewsets.ModelViewSet):
    """CRUD des tickets d'assistance — réservé à l'auteur du ticket."""
    serializer_class = TicketSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        # RM6 : chaque éleveur ne voit que ses propres tickets
        return Ticket.objects.filter(created_by=self.request.user).order_by("-created_at")

    def perform_create(self, serializer):
        serializer.save(created_by=self.request.user)

    @action(detail=True, methods=["post"], url_path="close")
    def close(self, request, pk=None):
        ticket = self.get_object()
        if ticket.status == "closed":
            return Response({"detail": "Ce ticket est déjà clos."}, status=status.HTTP_400_BAD_REQUEST)
        ticket.status = "closed"
        ticket.save(update_fields=["status"])
        return Response({"status": "Ticket clos avec succès."})


class TicketMessageViewSet(viewsets.ModelViewSet):
    """Messages liés à un ticket d'assistance."""
    serializer_class = TicketMessageSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        ticket_pk = self.kwargs.get("ticket_pk")
        return TicketMessage.objects.filter(
            ticket_id=ticket_pk,
            ticket__created_by=self.request.user
        )

    def perform_create(self, serializer):
        ticket_pk = self.kwargs.get("ticket_pk")
        ticket = Ticket.objects.get(pk=ticket_pk, created_by=self.request.user)
        serializer.save(author=self.request.user, ticket=ticket)
