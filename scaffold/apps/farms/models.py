import uuid
from django.db import models
from django.core.validators import MinValueValidator, MaxValueValidator


class Farm(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    owner = models.ForeignKey("accounts.User", on_delete=models.RESTRICT, related_name="farms")
    name = models.CharField(max_length=150)
    location_text = models.CharField(max_length=255, blank=True)
    latitude = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True,
                                    validators=[MinValueValidator(-90), MaxValueValidator(90)])
    longitude = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True,
                                     validators=[MinValueValidator(-180), MaxValueValidator(180)])
    capacity = models.PositiveIntegerField(null=True, blank=True)
    client_uuid = models.UUIDField(unique=True)
    sync_status = models.CharField(max_length=10, default="synced")
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = "farms"
        indexes = [models.Index(fields=["owner"])]
