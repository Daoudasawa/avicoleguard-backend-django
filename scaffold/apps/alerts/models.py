import uuid
from django.db import models
from apps.health.models import RiskLevel

class Alert(models.Model):
    class Status(models.TextChoices):
        OPEN = "open", "Ouvert"
        ACKNOWLEDGED = "acknowledged", "Acquitté"
        CLOSED = "closed", "Clos"

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    flock = models.ForeignKey("flocks.Flock", on_delete=models.CASCADE, related_name="alerts")
    health_analysis = models.ForeignKey("health.HealthAnalysis", on_delete=models.CASCADE, related_name="generated_alerts")
    rule_code = models.CharField(max_length=50)
    title = models.CharField(max_length=255)
    level = models.CharField(max_length=20, choices=RiskLevel.choices)
    status = models.CharField(max_length=15, choices=Status.choices, default=Status.OPEN)
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = "alerts"
        indexes = [
            models.Index(fields=["flock", "status"]),
            models.Index(fields=["flock", "rule_code", "created_at"]),
        ]
