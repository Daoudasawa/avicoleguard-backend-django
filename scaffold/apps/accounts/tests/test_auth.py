"""Tests de l'authentification — inscription, connexion, profil, déconnexion."""
import pytest
import uuid
from rest_framework.test import APIClient
from apps.accounts.models import User


@pytest.fixture
def api_client():
    return APIClient()


@pytest.fixture
def farmer_data():
    return {
        "username": f"farmer_{uuid.uuid4().hex[:8]}",
        "email": "farmer@test.com",
        "password": "TestPass123!",
        "password_confirm": "TestPass123!",
    }


@pytest.mark.django_db
def test_register_creates_user(api_client, farmer_data):
    """Un utilisateur peut s'inscrire via POST /api/v1/auth/register/."""
    response = api_client.post("/api/v1/auth/register/", farmer_data, format="json")
    assert response.status_code == 201
    assert User.objects.filter(username=farmer_data["username"]).exists()


@pytest.mark.django_db
def test_register_password_mismatch(api_client, farmer_data):
    """L'inscription échoue si les mots de passe ne correspondent pas."""
    farmer_data["password_confirm"] = "wrongpassword"
    response = api_client.post("/api/v1/auth/register/", farmer_data, format="json")
    assert response.status_code == 400


@pytest.mark.django_db
def test_login_returns_tokens(api_client, farmer_data):
    """Un utilisateur peut se connecter et reçoit access + refresh tokens."""
    # Inscription d'abord
    api_client.post("/api/v1/auth/register/", farmer_data, format="json")
    # Connexion
    response = api_client.post("/api/v1/auth/token/", {
        "username": farmer_data["username"],
        "password": farmer_data["password"],
    }, format="json")
    assert response.status_code == 200
    assert "access" in response.data
    assert "refresh" in response.data


@pytest.mark.django_db
def test_me_requires_authentication(api_client):
    """L'endpoint /me/ est protégé contre les accès non authentifiés."""
    response = api_client.get("/api/v1/auth/me/")
    assert response.status_code == 401


@pytest.mark.django_db
def test_me_returns_current_user(api_client, farmer_data):
    """Un utilisateur authentifié peut récupérer son propre profil."""
    api_client.post("/api/v1/auth/register/", farmer_data, format="json")
    login = api_client.post("/api/v1/auth/token/", {
        "username": farmer_data["username"],
        "password": farmer_data["password"],
    }, format="json")
    api_client.credentials(HTTP_AUTHORIZATION=f"Bearer {login.data['access']}")
    response = api_client.get("/api/v1/auth/me/")
    assert response.status_code == 200
    assert response.data["username"] == farmer_data["username"]
