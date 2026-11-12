import pytest
import uuid
from datetime import timedelta
from django.utils import timezone
from apps.accounts.models import User
from apps.farms.models import Farm
from apps.flocks.models import Flock
from apps.mortality.models import Mortality
from apps.alerts.models import Alert
from apps.health.models import AlertRule, RiskLevel
from apps.health.engine import run_health_analysis


@pytest.fixture
def farmer(db):
    return User.objects.create_user(username="farmer_rm12", password="password123", role=User.Role.FARMER)


@pytest.fixture
def flock(db, farmer):
    farm = Farm.objects.create(owner=farmer, name="Ferme Test RM12", client_uuid=uuid.uuid4())
    return Flock.objects.create(
        farm=farm,
        reference="LOT-RM12",
        initial_count=100,
        current_count=100,
        arrival_date="2026-01-01",
        client_uuid=uuid.uuid4(),
    )


@pytest.fixture
def mortality_rule(db):
    return AlertRule.objects.create(
        code="MORTALITY_DAILY_HIGH",
        description="Pic de mortalité anormal",
        threshold_value=5.0,  # 5%
        trend_window_days=1,
        severity=RiskLevel.ATTENTION,
        is_active=True,
    )


@pytest.mark.django_db
def test_rm12_anti_repetition_suppresses_duplicate_alert_within_24h(farmer, flock, mortality_rule):
    # Enregistrer une mortalité de 10% (10 / 100)
    Mortality.objects.create(
        flock=flock,
        date=timezone.now().date(),
        dead_count=10,
        client_uuid=uuid.uuid4(),
    )

    # Première analyse -> Déclenche l'alerte
    analysis1 = run_health_analysis(flock.id)
    assert analysis1 is not None
    assert Alert.objects.filter(flock=flock, rule_code=mortality_rule.code).count() == 1

    # Deuxième analyse immédiate (ou dans les 24h) -> RM12 anti-répétition empêche un doublon d'alerte
    analysis2 = run_health_analysis(flock.id)
    assert analysis2 is not None
    assert Alert.objects.filter(flock=flock, rule_code=mortality_rule.code).count() == 1


@pytest.mark.django_db
def test_rm12_permits_alert_after_24h_window(farmer, flock, mortality_rule):
    # Première alerte créée il y a plus de 24h
    Mortality.objects.create(
        flock=flock,
        date=timezone.now().date() - timedelta(days=2),
        dead_count=10,
        client_uuid=uuid.uuid4(),
    )
    analysis = run_health_analysis(flock.id)
    alert = Alert.objects.filter(flock=flock, rule_code=mortality_rule.code).first()
    assert alert is not None

    # Simuler que l'alerte date de 25 heures
    Alert.objects.filter(id=alert.id).update(created_at=timezone.now() - timedelta(hours=25))

    # Nouvelle mortalité sur la période récente
    Mortality.objects.create(
        flock=flock,
        date=timezone.now().date(),
        dead_count=8,
        client_uuid=uuid.uuid4(),
    )

    # Analyse -> La fenêtre de 24h étant passée, une nouvelle alerte peut être créée
    run_health_analysis(flock.id)
    assert Alert.objects.filter(flock=flock, rule_code=mortality_rule.code).count() == 2
