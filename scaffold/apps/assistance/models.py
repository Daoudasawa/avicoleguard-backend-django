from django.db import models
from django.utils import timezone
from uuid import uuid4

# Ticket system for farmer assistance.
# Each ticket is linked to a flock and created by a farmer (user).
# Messages are stored in a separate model linked to the ticket.

class Ticket(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid4, editable=False)
    flock = models.ForeignKey('flocks.Flock', on_delete=models.CASCADE, related_name='tickets')
    created_by = models.ForeignKey('accounts.User', on_delete=models.CASCADE, related_name='tickets')
    subject = models.CharField(max_length=200)
    description = models.TextField()
    status = models.CharField(max_length=20, default='open')  # open / in_progress / closed
    created_at = models.DateTimeField(default=timezone.now)
    # Offline‑first fields
    client_uuid = models.UUIDField(null=True, blank=True)
    sync_status = models.CharField(max_length=20, default='pending')

    class Meta:
        indexes = [
            models.Index(fields=['flock', 'status']),
        ]
        ordering = ['-created_at']

    def __str__(self):
        return f"Ticket {self.id} – {self.subject}"

class TicketMessage(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid4, editable=False)
    ticket = models.ForeignKey(Ticket, on_delete=models.CASCADE, related_name='messages')
    author = models.ForeignKey('accounts.User', on_delete=models.CASCADE, related_name='ticket_messages')
    content = models.TextField()
    created_at = models.DateTimeField(default=timezone.now)
    # Offline‑first fields
    client_uuid = models.UUIDField(null=True, blank=True)
    sync_status = models.CharField(max_length=20, default='pending')

    class Meta:
        ordering = ['created_at']

    def __str__(self):
        return f"Message {self.id} on Ticket {self.ticket.id}"
