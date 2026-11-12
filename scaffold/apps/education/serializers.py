from rest_framework import serializers
from .models import ContentCategory, EducationalContent


class ContentCategorySerializer(serializers.ModelSerializer):
    class Meta:
        model = ContentCategory
        fields = ["id", "name", "created_at"]


class EducationalContentSerializer(serializers.ModelSerializer):
    category_name = serializers.CharField(source="category.name", read_only=True)

    class Meta:
        model = EducationalContent
        fields = ["id", "category", "category_name", "title", "body", "published_at"]
        read_only_fields = ["id", "published_at"]
