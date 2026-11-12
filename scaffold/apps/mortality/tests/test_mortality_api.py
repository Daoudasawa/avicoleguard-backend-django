import pytest
import uuid
from rest_framework.test import APIClient
from apps.accounts.models import User
from apps.farms.models import Farm
from apps.flocks.models import Flock
from apps.mortality.models import Mortality


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
def test_record_mortality_api_and_cancel(create_farmer, auth_client):
    farmer = create_farmer("mort_farmer_api")
    farm = Farm.objects.create(owner=farmer, name="Ferme Mort", client_uuid=uuid.uuid4())
    flock = Flock.objects.create(
        farm=farm, reference="LOT-MORT-1", initial_count=100, current_count=100,
        arrival_date="2026-01-01", client_uuid=uuid.uuid4()
    )
    client = auth_client(farmer)

    payload = {
        "date": "2026-01-10",
        "dead_count": 5,
        "presumed_cause": "Coup de chaleur",
        "notes": "Ventilation défaillante",
    }

    # Enregistrement de la mortalité
    response = client.post(f"/api/v1/flocks/{flock.id}/mortalities/", payload, format="json")
    assert response.status_code == 201
    mort_id = response.data["id"]

    # Vérification que le lot a été mis à jour (100 - 5 = 95)
    flock.refresh_from_db()
    assert flock.current_count == 95

    # Annulation tracée de la mortalité (RM11)
    cancel_payload = {"reason": "Erreur de comptage, seulement 2 morts"}
    cancel_res = client.post(f"/api/v1/flocks/{flock.id}/mortalities/{mort_id}/cancel/", cancel_payload, format="json")
    assert cancel_res.status_code == 200
    assert cancel_res.data["cancelled_at"] is not None
    assert cancel_res.data["cancel_reason"] == cancel_payload["reason"]

    # Vérification du rétablissement de l'effectif
    flock.refresh_from_db()
    assert flock.current_count == 100


@pytest.mark.django_db
def test_record_mortality_exceeding_initial_count_rejected(create_farmer, auth_client):
    farmer = create_farmer("mort_excess_farmer")
    farm = Farm.objects.create(owner=farmer, name="Ferme Excess", client_uuid=uuid.uuid4())
    flock = Flock.objects.create(
        farm=farm, reference="LOT-EXCESS", initial_count=10, current_count=10,
        arrival_date="2026-01-01", client_uuid=uuid.uuid4()
    )
    client = auth_client(farmer)

    payload = {
        "date": "2026-01-10",
        "dead_count": 15,  # > 10
    }

    response = client.post(f"/api/v1/flocks/{flock.id}/mortalities/", payload, format="json")
    assert response.status_code == 400
    assert "dead_count" in response.data


@pytest.mark.django_db
def test_cannot_record_mortality_on_other_farmer_flock(create_farmer, auth_client):
    farmer_a = create_farmer("mort_farmer_a")
    farmer_b = create_farmer("mort_farmer_b")

    farm_b = Farm.objects.create(owner=farmer_b, name="Ferme B", client_uuid=uuid.uuid4())
    flock_b = Flock.objects.create(
        farm=farm_b, reference="LOT-B", initial_count=50, current_count=50,
        arrival_date="2026-01-01", client_uuid=uuid.uuid4()
    )

    client_a = auth_client(farmer_a)
    payload = {
        "date": "2026-01-10",
        "dead_count": 2,
    }

    response = client_a.post(f"/api/v1/flocks/{flock_b.id}/mortalities/", payload, format="json")
    assert response.status_code in [403, 404]
