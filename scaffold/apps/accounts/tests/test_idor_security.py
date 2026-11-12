import pytest
import uuid
from rest_framework.test import APIClient
from apps.accounts.models import User
from apps.farms.models import Farm
from apps.flocks.models import Flock
from apps.alerts.models import Alert
from apps.health.models import HealthAnalysis
from apps.recommendations.models import Recommendation
from apps.schedules.models import HealthSchedule


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
def test_farmer_cannot_view_recommendations_of_another_farmer_alert(create_farmer, auth_client):
    farmer_a = create_farmer("idor_farmer_a")
    farmer_b = create_farmer("idor_farmer_b")

    farm_a = Farm.objects.create(owner=farmer_a, name="Ferme A", client_uuid=uuid.uuid4())
    flock_a = Flock.objects.create(
        farm=farm_a, reference="LOT-A", initial_count=100, current_count=100,
        arrival_date="2026-01-01", client_uuid=uuid.uuid4()
    )
    analysis_a = HealthAnalysis.objects.create(flock=flock_a, risk_level="attention")
    alert_a = Alert.objects.create(
        flock=flock_a,
        health_analysis=analysis_a,
        title="Alerte Température",
        level="attention",
    )
    Recommendation.objects.create(alert=alert_a, content="Aérer d'urgence le bâtiment")

    # L'éleveur B tente d'accéder aux recommandations de l'alerte de A
    client_b = auth_client(farmer_b)
    response = client_b.get(f"/api/v1/alerts/{alert_a.id}/recommendations/")

    assert response.status_code == 200
    # Aucune recommandation de A ne doit être visible pour B
    assert len(response.data["results"]) == 0


@pytest.mark.django_db
def test_farmer_cannot_create_or_view_schedules_on_other_farmer_flock(create_farmer, auth_client):
    farmer_a = create_farmer("sched_farmer_a")
    farmer_b = create_farmer("sched_farmer_b")

    farm_a = Farm.objects.create(owner=farmer_a, name="Ferme Sched A", client_uuid=uuid.uuid4())
    flock_a = Flock.objects.create(
        farm=farm_a, reference="LOT-SCHED-A", initial_count=100, current_count=100,
        arrival_date="2026-01-01", client_uuid=uuid.uuid4()
    )

    schedule_a = HealthSchedule.objects.create(
        flock=flock_a, title="Vaccination Newcastle", scheduled_date="2026-02-01", client_uuid=uuid.uuid4()
    )

    client_b = auth_client(farmer_b)

    # L'éleveur B ne voit pas le calendrier de A
    list_res = client_b.get("/api/v1/schedules/")
    assert list_res.status_code == 200
    assert len(list_res.data["results"]) == 0

    # L'éleveur B ne peut pas consulter le détail
    detail_res = client_b.get(f"/api/v1/schedules/{schedule_a.id}/")
    assert detail_res.status_code == 404

    # L'éleveur B ne peut pas créer un événement sur le lot de A
    post_res = client_b.post("/api/v1/schedules/", {
        "flock": str(flock_a.id),
        "title": "Fausse visite",
        "scheduled_date": "2026-02-15",
    }, format="json")
    assert post_res.status_code == 400
    assert "flock" in post_res.data
