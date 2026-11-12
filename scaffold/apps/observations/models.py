import uuid
from django.db import models

class Observation(models.Model):
    class Type(models.TextChoices):
        ABNORMAL_BEHAVIOR = "abnormal_behavior", "Comportement anormal"
        RESPIRATORY = "respiratory", "Respiratoire"
        FEEDING = "feeding", "Alimentation"
        DIGESTIVE = "digestive", "Digestif"
        PLUMAGE = "plumage", "Plumage"
        LOCOMOTOR = "locomotor", "Locomoteur"
        OTHER = "other", "Autre"

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    flock = models.ForeignKey("flocks.Flock", on_delete=models.CASCADE, related_name="observations")
    date = models.DateTimeField()
    type = models.CharField(max_length=25, choices=Type.choices)
    description = models.TextField(blank=True)
    
    cancelled_at = models.DateTimeField(null=True, blank=True)
    cancel_reason = models.CharField(max_length=255, blank=True)
    
    client_uuid = models.UUIDField(unique=True)
    sync_status = models.CharField(max_length=10, default="pending")
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = "observations"
        indexes = [models.Index(fields=["flock", "date"])]

    objects = models.Manager()

    class ActiveManager(models.Manager):
        def get_queryset(self):
            return super().get_queryset().filter(cancelled_at__isnull=True)

    active = ActiveManager()
