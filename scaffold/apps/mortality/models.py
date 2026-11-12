import uuid
from django.db import models
from django.core.validators import MinValueValidator


class ActiveMortalityManager(models.Manager):
    """Exclut les saisies annulées (RM11) des calculs du moteur de règles."""
    def get_queryset(self):
        return super().get_queryset().filter(cancelled_at__isnull=True)


class Mortality(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    flock = models.ForeignKey("flocks.Flock", on_delete=models.CASCADE, related_name="mortalities")
    date = models.DateField()
    dead_count = models.PositiveIntegerField(validators=[MinValueValidator(1)])
    presumed_cause = models.CharField(max_length=150, blank=True)
    notes = models.TextField(blank=True)
    # RM11 : correction/annulation toujours tracée, jamais de suppression physique
    cancelled_at = models.DateTimeField(null=True, blank=True)
    cancel_reason = models.CharField(max_length=255, blank=True)
    client_uuid = models.UUIDField(unique=True)
    sync_status = models.CharField(max_length=10, default="pending")
    created_at = models.DateTimeField(auto_now_add=True)

    objects = models.Manager()
    active = ActiveMortalityManager()

    class Meta:
        db_table = "mortalities"
        indexes = [models.Index(fields=["flock", "date"])]
