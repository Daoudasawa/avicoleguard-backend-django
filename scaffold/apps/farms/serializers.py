import uuid
from rest_framework import serializers
from .models import Farm


class FarmSerializer(serializers.ModelSerializer):
    client_uuid = serializers.UUIDField(required=False, default=uuid.uuid4)
    owner_username = serializers.CharField(source="owner.username", read_only=True)

    class Meta:
        model = Farm
        fields = [
            "id",
            "owner",
            "owner_username",
            "name",
            "location_text",
            "latitude",
            "longitude",
            "capacity",
            "client_uuid",
            "sync_status",
            "created_at",
            "updated_at",
        ]
        read_only_fields = ["id", "owner", "owner_username", "created_at", "updated_at"]
