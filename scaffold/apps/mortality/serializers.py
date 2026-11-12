import uuid
from rest_framework import serializers
from .models import Mortality


class MortalitySerializer(serializers.ModelSerializer):
    client_uuid = serializers.UUIDField(required=False, default=uuid.uuid4)

    class Meta:
        model = Mortality
        fields = [
            "id",
            "flock",
            "date",
            "dead_count",
            "presumed_cause",
            "notes",
            "cancelled_at",
            "cancel_reason",
            "client_uuid",
            "sync_status",
            "created_at",
        ]
        read_only_fields = [
            "id",
            "flock",
            "cancelled_at",
            "cancel_reason",
            "created_at",
        ]


class MortalityCancelSerializer(serializers.Serializer):
    reason = serializers.CharField(max_length=255, required=True)
