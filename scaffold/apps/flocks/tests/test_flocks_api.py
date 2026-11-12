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
def test_farmer_can_create_flock_and_close(create_farmer, auth_client):
    farmer = create_farmer("flock_farmer_1")
    farm = Farm.objects.create(owner=farmer, name="Ferme 1", client_uuid=uuid.uuid4())
    client = auth_client(farmer)

    payload = {
        "farm": str(farm.id),
        "reference": "LOT-2026-A",
        "breed": "Goliath",
        "sex": "mixed",
        "initial_count": 500,
        "arrival_date": "2026-03-01",
    }

    # Création du lot
    response = client.post("/api/v1/flocks/", payload, format="json")
    assert response.status_code == 201
    assert response.data["current_count"] == 500
    assert response.data["status"] == "active"
    flock_id = response.data["id"]

    # Clôture du lot via /close/
    close_res = client.post(f"/api/v1/flocks/{flock_id}/close/")
    assert close_res.status_code == 200
    assert close_res.data["status"] == "closed"
    assert close_res.data["end_date"] is not None

    # Re-clôture rejetée
    close_again = client.post(f"/api/v1/flocks/{flock_id}/close/")
    assert close_again.status_code == 400


@pytest.mark.django_db
def test_flock_cannot_be_attached_to_other_farmer_farm(create_farmer, auth_client):
    farmer_a = create_farmer("flock_farmer_a")
    farmer_b = create_farmer("flock_farmer_b")

    farm_b = Farm.objects.create(owner=farmer_b, name="Ferme de B", client_uuid=uuid.uuid4())

    client_a = auth_client(farmer_a)
    payload = {
        "farm": str(farm_b.id),
        "reference": "LOT-ILLEGAL",
        "initial_count": 100,
        "arrival_date": "2026-03-01",
    }

    response = client_a.post("/api/v1/flocks/", payload, format="json")
    assert response.status_code == 400
    assert "farm" in response.data


@pytest.mark.django_db
def test_flock_current_count_validation(create_farmer, auth_client):
    farmer = create_farmer("flock_count_farmer")
    farm = Farm.objects.create(owner=farmer, name="Ferme", client_uuid=uuid.uuid4())
    client = auth_client(farmer)

    payload = {
        "farm": str(farm.id),
        "reference": "LOT-COUNT-ERR",
        "initial_count": 100,
        "current_count": 150,  # Ne peut pas excéder initial_count
        "arrival_date": "2026-03-01",
    }

    response = client.post("/api/v1/flocks/", payload, format="json")
    assert response.status_code == 400
    assert "current_count" in response.data
