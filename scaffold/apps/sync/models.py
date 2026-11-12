import uuid
from django.db import models
from django.conf import settings

class SynchronizationLog(models.Model):
    class Status(models.TextChoices):
        SUCCESS = "success", "Succès"
        PARTIAL = "partial", "Partiel (avec erreurs)"
        FAILED = "failed", "Échec"

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="sync_logs")
    device_id = models.CharField(max_length=255, blank=True)
    
    started_at = models.DateTimeField(auto_now_add=True)
    completed_at = models.DateTimeField(null=True, blank=True)
    
    status = models.CharField(max_length=15, choices=Status.choices, default=Status.FAILED)
    
    pull_count = models.PositiveIntegerField(default=0)
    push_count = models.PositiveIntegerField(default=0)
    
    errors = models.JSONField(default=dict, blank=True)

    class Meta:
        db_table = "synchronization_logs"
        indexes = [
            models.Index(fields=["user", "started_at"]),
        ]
