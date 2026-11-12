from rest_framework import serializers
from .models import Ticket, TicketMessage

class TicketSerializer(serializers.ModelSerializer):
    class Meta:
        model = Ticket
        fields = ["id", "flock", "created_by", "subject", "description", "status", "created_at", "client_uuid", "sync_status"]
        read_only_fields = ["id", "created_at"]

class TicketMessageSerializer(serializers.ModelSerializer):
    class Meta:
        model = TicketMessage
        fields = ["id", "ticket", "author", "content", "created_at", "client_uuid", "sync_status"]
        read_only_fields = ["id", "created_at"]
