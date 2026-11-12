import uuid
from django.contrib.auth.models import AbstractUser
from django.db import models


class User(AbstractUser):
    class Role(models.TextChoices):
        FARMER = "farmer", "Éleveur"
        VETERINARIAN = "veterinarian", "Vétérinaire"
        TECHNICIAN = "technician", "Technicien"
        COOPERATIVE_MANAGER = "cooperative_manager", "Responsable coopérative"
        ADMIN = "admin", "Administrateur"

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    phone = models.CharField(max_length=30, blank=True, unique=False)
    role = models.CharField(max_length=25, choices=Role.choices, default=Role.FARMER)
    is_active_account = models.BooleanField(default=True)  # distinct du is_active Django (session)

    class Meta:
        db_table = "users"


class FarmerProfile(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name="farmer_profile")
    preferred_language = models.CharField(max_length=10, blank=True)


class VeterinarianProfile(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name="veterinarian_profile")
    license_number = models.CharField(max_length=50, blank=True)
    specialty = models.CharField(max_length=100, blank=True)
    is_available = models.BooleanField(default=True)


class TechnicianProfile(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name="technician_profile")
    structure = models.CharField(max_length=150, blank=True)
    is_available = models.BooleanField(default=True)
