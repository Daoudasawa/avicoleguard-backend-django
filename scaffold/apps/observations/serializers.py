from rest_framework import serializers
from .models import Observation
from django.utils import timezone

class ObservationCreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = Observation
        fields = ["id", "client_uuid", "date", "type", "description"]
        read_only_fields = ["id"]

    def validate_date(self, value):
        if value > timezone.now():
            raise serializers.ValidationError("La date ne peut pas être dans le futur.")
        return value

class ObservationSerializer(serializers.ModelSerializer):
    class Meta:
        model = Observation
        fields = [
            "id", "client_uuid", "date", "type", "description",
            "cancelled_at", "cancel_reason", "sync_status", "created_at"
        ]
        read_only_fields = fields
