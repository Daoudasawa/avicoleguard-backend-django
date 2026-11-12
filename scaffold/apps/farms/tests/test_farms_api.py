import pytest
import uuid
from rest_framework.test import APIClient
from apps.accounts.models import User
from apps.farms.models import Farm


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
def test_farmer_can_create_and_list_farms(create_farmer, auth_client):
    farmer = create_farmer("farmer_farm_1")
    client = auth_client(farmer)

    payload = {
        "name": "Ferme du Faso",
        "location_text": "Kamboinsé, Ouagadougou",
        "latitude": "12.456789",
        "longitude": "-1.543210",
        "capacity": 1500,
    }

    response = client.post("/api/v1/farms/", payload, format="json")
    assert response.status_code == 201
    assert response.data["name"] == payload["name"]
    assert response.data["owner_username"] == farmer.username
    assert "client_uuid" in response.data

    list_response = client.get("/api/v1/farms/")
    assert list_response.status_code == 200
    assert len(list_response.data["results"]) == 1


@pytest.mark.django_db
def test_farm_isolation_between_farmers(create_farmer, auth_client):
    farmer_a = create_farmer("farmer_a_farm")
    farmer_b = create_farmer("farmer_b_farm")

    farm_a = Farm.objects.create(
        owner=farmer_a,
        name="Ferme de A",
        client_uuid=uuid.uuid4(),
    )

    client_b = auth_client(farmer_b)

    # L'éleveur B ne doit pas voir la ferme de A
    list_b = client_b.get("/api/v1/farms/")
    assert list_b.status_code == 200
    assert len(list_b.data["results"]) == 0

    # L'éleveur B ne peut pas consulter directement la ferme de A
    detail_b = client_b.get(f"/api/v1/farms/{farm_a.id}/")
    assert detail_b.status_code == 404

    # L'éleveur B ne peut pas modifier la ferme de A
    patch_b = client_b.patch(f"/api/v1/farms/{farm_a.id}/", {"name": "Piraté"}, format="json")
    assert patch_b.status_code == 404
