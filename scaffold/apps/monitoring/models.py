import uuid
from django.db import models

class DailyMonitoring(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    flock = models.ForeignKey("flocks.Flock", on_delete=models.CASCADE, related_name="daily_monitorings")
    date = models.DateField()
    temperature = models.DecimalField(max_digits=5, decimal_places=2, null=True, blank=True)
    water_consumption = models.DecimalField(max_digits=8, decimal_places=2, null=True, blank=True)
    feed_consumption = models.DecimalField(max_digits=8, decimal_places=2, null=True, blank=True)
    average_weight = models.DecimalField(max_digits=6, decimal_places=2, null=True, blank=True)
    
    cancelled_at = models.DateTimeField(null=True, blank=True)
    cancel_reason = models.CharField(max_length=255, blank=True)
    
    client_uuid = models.UUIDField(unique=True)
    sync_status = models.CharField(max_length=10, default="pending")
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = "daily_monitorings"
        indexes = [models.Index(fields=["flock", "date"])]

    objects = models.Manager()

    class ActiveManager(models.Manager):
        def get_queryset(self):
            return super().get_queryset().filter(cancelled_at__isnull=True)

    active = ActiveManager()
