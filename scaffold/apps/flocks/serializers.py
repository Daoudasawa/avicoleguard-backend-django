import uuid
from rest_framework import serializers
from .models import Flock


class FlockSerializer(serializers.ModelSerializer):
    client_uuid = serializers.UUIDField(required=False, default=uuid.uuid4)
    current_count = serializers.IntegerField(required=False)
    mortality_rate = serializers.FloatField(read_only=True)
    farm_name = serializers.CharField(source="farm.name", read_only=True)

    class Meta:
        model = Flock
        fields = [
            "id",
            "farm",
            "farm_name",
            "reference",
            "breed",
            "sex",
            "initial_count",
            "current_count",
            "arrival_date",
            "end_date",
            "status",
            "mortality_rate",
            "client_uuid",
            "sync_status",
            "created_at",
            "updated_at",
        ]
        read_only_fields = ["id", "farm_name", "mortality_rate", "created_at", "updated_at"]

    def validate_farm(self, value):
        request = self.context.get("request")
        if request and request.user.is_authenticated:
            if value.owner != request.user:
                raise serializers.ValidationError("Vous ne pouvez pas rattacher un lot à une ferme qui ne vous appartient pas.")
        return value

    def validate(self, attrs):
        initial = attrs.get("initial_count")
        if initial is None and self.instance:
            initial = self.instance.initial_count

        current = attrs.get("current_count")
        if current is None and not self.instance:
            # À la création, l'effectif actuel équivaut par défaut à l'effectif initial
            attrs["current_count"] = initial
            current = initial

        if current is not None and initial is not None and current > initial:
            raise serializers.ValidationError({
                "current_count": "L'effectif actuel ne peut pas excéder l'effectif initial."
            })

        return attrs
