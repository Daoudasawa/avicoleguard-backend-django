from .models import AuditLog


def log_action(*, user, action: str, entity_type: str, entity_id, metadata: dict | None = None) -> AuditLog:
    return AuditLog.objects.create(
        user=user, action=action, entity_type=entity_type, entity_id=entity_id, metadata=metadata or {},
    )
