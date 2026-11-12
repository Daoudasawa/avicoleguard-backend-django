from django.db import models
from django.utils import timezone
from uuid import uuid4

class Notification(models.Model):
    class Type(models.TextChoices):
        ALERT = "alert", "Alerte"
        SCHEDULE = "schedule", "Rappel de calendrier"
        ASSISTANCE = "assistance", "Réponse assistance"
        RECOMMENDATION = "recommendation", "Recommandation"
        GENERAL = "general", "Général"

    id = models.UUIDField(primary_key=True, default=uuid4, editable=False)
    user = models.ForeignKey('accounts.User', on_delete=models.CASCADE, related_name='notifications')
    title = models.CharField(max_length=200)
    message = models.TextField()
    type = models.CharField(max_length=20, choices=Type.choices, default=Type.GENERAL)
    created_at = models.DateTimeField(default=timezone.now)
    read_at = models.DateTimeField(null=True, blank=True)
    # Offline‑first fields
    client_uuid = models.UUIDField(null=True, blank=True)
    sync_status = models.CharField(max_length=20, default='pending')

    class Meta:
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['user', 'type', 'created_at']),
        ]

    def __str__(self):
        return f"{self.title} ({self.type}) for {self.user.email}"
