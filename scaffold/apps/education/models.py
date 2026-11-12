from django.db import models
from django.utils import timezone
from uuid import uuid4

class ContentCategory(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid4, editable=False)
    name = models.CharField(max_length=100, unique=True)
    created_at = models.DateTimeField(default=timezone.now)

    class Meta:
        db_table = "education_categories"
        ordering = ["name"]

    def __str__(self):
        return self.name

class EducationalContent(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid4, editable=False)
    category = models.ForeignKey(ContentCategory, on_delete=models.SET_NULL, null=True, related_name="contents")
    title = models.CharField(max_length=200)
    body = models.TextField()
    published_at = models.DateTimeField(default=timezone.now)
    # Offline‑first fields for potential push of new content to mobile
    client_uuid = models.UUIDField(null=True, blank=True)
    sync_status = models.CharField(max_length=20, default="pending")

    class Meta:
        db_table = "educational_contents"
        ordering = ["-published_at"]

    def __str__(self):
        return self.title
