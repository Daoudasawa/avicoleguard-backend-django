import uuid
from django.db import models
from django.core.validators import MinValueValidator


class Flock(models.Model):
    class Sex(models.TextChoices):
        MALE = "male", "Mâle"
        FEMALE = "female", "Femelle"
        MIXED = "mixed", "Mixte"

    class Status(models.TextChoices):
        ACTIVE = "active", "Actif"
        CLOSED = "closed", "Clôturé"

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    farm = models.ForeignKey("farms.Farm", on_delete=models.CASCADE, related_name="flocks")
    reference = models.CharField(max_length=50)
    breed = models.CharField(max_length=100, blank=True)
    sex = models.CharField(max_length=10, choices=Sex.choices, default=Sex.MIXED)
    initial_count = models.PositiveIntegerField(validators=[MinValueValidator(1)])
    current_count = models.PositiveIntegerField()
    arrival_date = models.DateField()
    end_date = models.DateField(null=True, blank=True)
    status = models.CharField(max_length=10, choices=Status.choices, default=Status.ACTIVE)
    client_uuid = models.UUIDField(unique=True)
    sync_status = models.CharField(max_length=10, default="synced")
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = "flocks"
        constraints = [
            models.CheckConstraint(
                condition=models.Q(current_count__lte=models.F("initial_count")),
                name="flock_current_count_lte_initial",
            ),
            models.UniqueConstraint(fields=["farm", "reference"], name="unique_flock_reference_per_farm"),
        ]
        indexes = [models.Index(fields=["farm", "status"])]

    @property
    def mortality_rate(self) -> float:
        if self.initial_count == 0:
            return 0.0
        return round((self.initial_count - self.current_count) / self.initial_count * 100, 2)
