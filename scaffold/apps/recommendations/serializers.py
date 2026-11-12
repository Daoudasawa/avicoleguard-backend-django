from rest_framework import serializers
from .models import Recommendation

class RecommendationSerializer(serializers.ModelSerializer):
    class Meta:
        model = Recommendation
        fields = ["id", "alert", "content", "generated_by", "validated_by_professional", "created_at", "updated_at"]
        read_only_fields = ["id", "created_at", "updated_at"]
