import uuid
from django.db import models

class Recommendation(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    alert = models.ForeignKey("alerts.Alert", on_delete=models.CASCADE, related_name="recommendations")
    content = models.TextField()
    generated_by = models.CharField(max_length=100) # System or User name
    validated_by_professional = models.BooleanField(default=False)
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = "recommendations"
