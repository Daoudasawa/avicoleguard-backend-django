import uuid
from rest_framework import serializers
from .models import HealthSchedule


class HealthScheduleSerializer(serializers.ModelSerializer):
    client_uuid = serializers.UUIDField(required=False, default=uuid.uuid4)
    flock_reference = serializers.CharField(source="flock.reference", read_only=True)

    class Meta:
        model = HealthSchedule
        fields = [
            "id",
            "flock",
            "flock_reference",
            "title",
            "description",
            "scheduled_date",
            "completed",
            "client_uuid",
            "sync_status",
            "created_at",
            "updated_at",
        ]
        read_only_fields = ["id", "flock_reference", "created_at", "updated_at"]

    def validate_flock(self, value):
        request = self.context.get("request")
        if request and request.user.is_authenticated:
            if value.farm.owner != request.user and request.user.role not in ["veterinarian", "technician", "admin"]:
                raise serializers.ValidationError("Vous ne pouvez pas planifier d'événement pour un lot qui ne vous appartient pas.")
        return value
