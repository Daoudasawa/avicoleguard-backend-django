from rest_framework import serializers
from .models import Alert

class AlertSerializer(serializers.ModelSerializer):
    class Meta:
        model = Alert
        fields = [
            "id", "flock", "health_analysis", "rule_code", 
            "title", "level", "status", "created_at", "updated_at"
        ]
        read_only_fields = fields
