"""Tests des règles métier critiques RM1-RM4, RM7, RM11 (voir CLAUDE.md §4)."""
import pytest
from rest_framework.exceptions import ValidationError

from apps.flocks.models import Flock
from apps.farms.models import Farm
from apps.accounts.models import User
from apps.mortality.services import record_mortality, cancel_mortality
import uuid


@pytest.fixture
def farmer(db):
    return User.objects.create_user(username="farmer1", password="x", role=User.Role.FARMER)


@pytest.fixture
def flock(db, farmer):
    farm = Farm.objects.create(owner=farmer, name="Ferme Test", client_uuid=uuid.uuid4())
    return Flock.objects.create(
        farm=farm, reference="LOT-001", initial_count=100, current_count=100,
        arrival_date="2026-01-01", client_uuid=uuid.uuid4(),
    )


@pytest.mark.django_db
def test_mortality_reduces_current_count(farmer, flock):
    record_mortality(flock_id=flock.id, user=farmer, data={
        "date": "2026-01-02", "dead_count": 5, "client_uuid": uuid.uuid4(),
    })
    flock.refresh_from_db()
    assert flock.current_count == 95


@pytest.mark.django_db
def test_mortality_cannot_exceed_initial_count(farmer, flock):
    with pytest.raises(ValidationError):
        record_mortality(flock_id=flock.id, user=farmer, data={
            "date": "2026-01-02", "dead_count": 150, "client_uuid": uuid.uuid4(),
        })


@pytest.mark.django_db
def test_closed_flock_rejects_new_mortality(farmer, flock):
    flock.status = Flock.Status.CLOSED
    flock.save()
    with pytest.raises(ValidationError):
        record_mortality(flock_id=flock.id, user=farmer, data={
            "date": "2026-01-02", "dead_count": 1, "client_uuid": uuid.uuid4(),
        })


@pytest.mark.django_db
def test_cancel_mortality_restores_current_count(farmer, flock):
    mortality = record_mortality(flock_id=flock.id, user=farmer, data={
        "date": "2026-01-02", "dead_count": 5, "client_uuid": uuid.uuid4(),
    })
    cancel_mortality(mortality_id=mortality.id, user=farmer, reason="Doublon de saisie")
    flock.refresh_from_db()
    mortality.refresh_from_db()
    assert flock.current_count == 100
    assert mortality.cancelled_at is not None
