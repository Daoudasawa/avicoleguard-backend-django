from rest_framework import serializers
from .models import DailyMonitoring
from django.utils import timezone

class DailyMonitoringCreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = DailyMonitoring
        fields = [
            "id", "client_uuid", "date", "temperature", 
            "water_consumption", "feed_consumption", "average_weight"
        ]
        read_only_fields = ["id"]

    def validate_date(self, value):
        if value > timezone.now().date():
            raise serializers.ValidationError("La date ne peut pas être dans le futur.")
        return value

class DailyMonitoringSerializer(serializers.ModelSerializer):
    class Meta:
        model = DailyMonitoring
        fields = [
            "id", "client_uuid", "date", "temperature", 
            "water_consumption", "feed_consumption", "average_weight",
            "cancelled_at", "cancel_reason", "sync_status", "created_at"
        ]
        read_only_fields = fields
