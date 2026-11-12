import uuid
from django.db import models

class RiskLevel(models.TextChoices):
    INFORMATION = "information", "Information"
    ATTENTION = "attention", "Attention"
    PREOCCUPANT = "preoccupant", "Préoccupant"
    CRITIQUE = "critique", "Critique"

class AlertRule(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    code = models.CharField(max_length=50, unique=True)
    description = models.CharField(max_length=255)
    threshold_value = models.DecimalField(max_digits=10, decimal_places=4)
    trend_window_days = models.PositiveIntegerField(default=1)
    severity = models.CharField(max_length=20, choices=RiskLevel.choices)
    is_active = models.BooleanField(default=True)
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = "alert_rules"
        
    def __str__(self):
        return f"{self.code} - {self.description}"

class HealthAnalysis(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    flock = models.ForeignKey("flocks.Flock", on_delete=models.CASCADE, related_name="health_analyses")
    run_at = models.DateTimeField(auto_now_add=True)
    risk_level = models.CharField(max_length=20, choices=RiskLevel.choices, default=RiskLevel.INFORMATION)
    score = models.DecimalField(max_digits=5, decimal_places=2, default=0.0)
    confidence = models.DecimalField(max_digits=5, decimal_places=2, default=1.0)
    explanation = models.TextField(blank=True)

    class Meta:
        db_table = "health_analyses"
        indexes = [models.Index(fields=["flock", "run_at"])]
