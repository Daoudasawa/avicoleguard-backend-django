"""Tests d'isolation des données (Règle RM6) — un éleveur ne voit pas les données d'un autre."""
import pytest
import uuid
from rest_framework.test import APIClient
from apps.accounts.models import User
from apps.farms.models import Farm
from apps.flocks.models import Flock


@pytest.fixture
def create_farmer(db):
    def _create(username):
        return User.objects.create_user(
            username=username,
            password="TestPass123!",
            role=User.Role.FARMER,
        )
    return _create


@pytest.fixture
def create_flock(db):
    def _create(owner, ref="LOT-001"):
        farm = Farm.objects.create(owner=owner, name=f"Ferme {owner.username}", client_uuid=uuid.uuid4())
        return Flock.objects.create(
            farm=farm, reference=ref, initial_count=100, current_count=100,
            arrival_date="2026-01-01", client_uuid=uuid.uuid4(),
        )
    return _create


@pytest.fixture
def auth_client(db):
    def _client(user):
        client = APIClient()
        response = client.post("/api/v1/auth/token/", {
            "username": user.username,
            "password": "TestPass123!",
        }, format="json")
        client.credentials(HTTP_AUTHORIZATION=f"Bearer {response.data['access']}")
        return client
    return _client


@pytest.mark.django_db
def test_farmer_cannot_see_other_farmers_alerts(create_farmer, create_flock, auth_client):
    """Un éleveur A ne peut pas accéder aux alertes d'un lot appartenant à l'éleveur B."""
    farmer_a = create_farmer("farmer_a")
    farmer_b = create_farmer("farmer_b")
    flock_b = create_flock(farmer_b, ref="LOT-B01")

    # L'éleveur A essaie d'accéder aux alertes du lot de B
    client_a = auth_client(farmer_a)
    response = client_a.get(f"/api/v1/flocks/{flock_b.id}/alerts/")
    # Doit être refusé (403) ou vide — aucune donnée de B ne doit fuiter
    assert response.status_code in [403, 404]


@pytest.mark.django_db
def test_notifications_are_user_scoped(create_farmer, auth_client, db):
    """Un utilisateur ne voit que ses propres notifications."""
    farmer_a = create_farmer("notif_farmer_a")
    farmer_b = create_farmer("notif_farmer_b")

    from apps.notifications.models import Notification
    # Créer une notification pour B uniquement
    Notification.objects.create(user=farmer_b, title="Pour B", message="test", type="general")

    # Farmer A ne doit pas voir cette notification
    client_a = auth_client(farmer_a)
    response = client_a.get("/api/v1/notifications/")
    assert response.status_code == 200
    assert len(response.data["results"]) == 0


@pytest.mark.django_db
def test_unauthenticated_cannot_access_api(db):
    """Un utilisateur non authentifié ne peut pas accéder à l'API protégée."""
    client = APIClient()
    response = client.get("/api/v1/notifications/")
    assert response.status_code == 401
