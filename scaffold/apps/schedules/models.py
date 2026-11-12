from django.db import models
from django.utils import timezone
from uuid import uuid4

# Agenda des opérations de santé (vaccins, déparasitage, visites vétérinaires)
class HealthSchedule(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid4, editable=False)
    flock = models.ForeignKey('flocks.Flock', on_delete=models.CASCADE, related_name='health_schedules')
    title = models.CharField(max_length=200)
    description = models.TextField(blank=True)
    scheduled_date = models.DateField()
    completed = models.BooleanField(default=False)
    # Offline‑first fields
    client_uuid = models.UUIDField(null=True, blank=True)
    sync_status = models.CharField(max_length=20, default='pending')  # pending / synced / failed
    created_at = models.DateTimeField(default=timezone.now)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'health_schedules'
        ordering = ['scheduled_date']
        indexes = [
            models.Index(fields=['flock', 'scheduled_date']),
        ]

    def __str__(self):
        return f"{self.title} for {self.flock.name} on {self.scheduled_date}"
