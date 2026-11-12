# ADDENDUM TECHNIQUE — Migration du backend vers Django (Python)

*Ce document remplace, dans le CAHIER_DES_CHARGES_FINAL_AVICOLE.md, toutes les sections dépendantes du choix technologique backend (§15 partiellement, §16, §17, §18, §19, §29, §35, §36 partiellement, §41). Toutes les autres sections restent valables sans changement : offline-first (§21), moteur de règles métier (§22), UML de cas d'utilisation et de classes au niveau domaine (§14-15.1, indépendants du langage), sécurité au niveau principes (§20), business model, marché, SWOT, MVP, risques, critères d'acceptation.*

**DÉCISION VALIDÉE** *(par le porteur de projet, remplace la stack Laravel de la V0/V1)* : le backend sera développé en **Python avec Django** (+ Django REST Framework pour l'API mobile), avec **PostgreSQL** inchangé comme base de données.

---

## 1. Justification de la décision (rappel)

- **Cohérence long terme avec l'axe IA** : le moteur de règles (V1) et les futurs modèles ML (V2-V4, §29 du cahier final) partagent le même langage et le même écosystème (`pandas`, `scikit-learn`, `SHAP`), évitant l'architecture à deux services de la V0 (Laravel + FastAPI séparé).
- **Un seul service applicatif** du MVP à la V4 : moins de complexité opérationnelle qu'un découplage de langage introduit en cours de route.
- Aucune perte sur les autres exigences du cahier (offline-first, sécurité, REST, tests) : Django/DRF couvre les mêmes besoins que Laravel/Sanctum avec des mécanismes équivalents.

## 2. Stack technique (remplace §17 du cahier final)

| Domaine | Choix V0 (Laravel) | **Choix retenu (Django)** | Équivalence |
|---|---|---|---|
| Langage backend | PHP 8.3+ | **Python 3.12+** *(version à revérifier auprès de python.org au démarrage — Règle 8)* | — |
| Framework | Laravel 12 | **Django 5.x (LTS recommandée)** *(version exacte à revérifier sur djangoproject.com)* | — |
| API REST | Laravel + API Resources | **Django REST Framework (DRF)** | Serializers ≈ API Resources |
| Auth API | Laravel Sanctum | **DRF TokenAuthentication ou `djangorestframework-simplejwt`** *(PROPOSITION : simplejwt, plus adapté à un client mobile avec refresh token que le token statique DRF de base — à valider)* | Sanctum → SimpleJWT |
| ORM | Eloquent | **Django ORM** | Modèles Eloquent → Modèles Django |
| Validation | Form Requests | **Serializers DRF (`validate_*`, `validators=`)** | FormRequest → Serializer |
| Permissions/RBAC | Policies Laravel | **DRF Permissions (`BasePermission`) + `django-guardian` si object-level fin nécessaire** | Policy → Permission class |
| Base de données | PostgreSQL | **PostgreSQL (inchangé)** | — |
| Géo (optionnel, non activé MVP) | PostGIS | **GeoDjango (PostGIS) si réactivé en V2+** | — |
| Tâches asynchrones/planifiées | Laravel Queue + Scheduler | **Celery + Celery Beat** (avec **Redis** comme broker, déjà prévu en V0) | Job/Scheduler → Task Celery |
| Notifications | Laravel Notifications | **Django signals + service dédié** (FCM pour push, `django.core.mail` si email) | — |
| Documentation API | Swagger/L5-Swagger | **drf-spectacular** (génère OpenAPI 3 depuis les serializers/viewsets) | — |
| Tests | Pest/PHPUnit | **pytest + pytest-django** (ou `unittest`/`TestCase` Django natif) | — |
| Admin/back-office | À construire (Laravel Nova ou custom) | **Django Admin natif** *(avantage Django : back-office contenus éducatifs/règles d'alerte quasi gratuit dès le départ — voir §5)* | — |
| ML/IA (V2+) | Service Python FastAPI séparé | **Intégré nativement** : `scikit-learn`, `pandas`, `numpy`, `shap` dans la même codebase Django | Suppression du service séparé |
| Infrastructure | Docker + Nginx + Redis | **Inchangé** (Docker + Nginx + Redis + Celery worker) | — |


## 3. Architecture technique (remplace §16)

```text
┌─────────────────────┐        HTTPS/JSON        ┌──────────────────────────────┐
│   App Flutter          │ ───────────────────────▶ │   API Django + DRF               │
│   (offline-first)       │ ◀─────────────────────── │   SimpleJWT + Permissions         │
└─────────────────────┘                          │   (moteur de règles + ML futur)  │
                                                   └───────────┬──────────────────┘
                                                               │
                                       ┌───────────────────────┼───────────────────────┐
                                       ▼                       ▼                       ▼
                               PostgreSQL                Redis (Celery broker/  Stockage fichiers
                                                          cache)                  (photos assistance)
                                                               │
                                                               ▼
                                                     Celery worker (analyse
                                                     sanitaire asynchrone,
                                                     rappels planifiés, V2+ ML)
```

**Différence notable vs V0** : dans la V0 (Laravel), l'analyse sanitaire pouvait être synchrone (déclenchée dans la requête HTTP de la mortalité) ou passer par une Queue. **PROPOSITION renforcée pour Django** : traiter systématiquement l'analyse sanitaire en tâche asynchrone Celery dès le MVP (`analyze_flock.delay(flock_id)`), pour que l'ajout futur de calculs ML (V2+, potentiellement plus lourds) ne nécessite aucun changement d'architecture — seulement l'enrichissement de la tâche existante.

## 4. Architecture applicative Django (remplace §16 "Architecture Laravel")

Organisation en **apps Django** (équivalent du modular monolith Laravel, principe VALIDÉ et conservé — Règle 3, pas de sur-architecture) :

```text
avicoleguard/
├── config/                    (settings, urls racine, celery.py, wsgi/asgi)
│
├── apps/
│   ├── accounts/               (User custom, profils farmer/vet/technician/admin/coop, auth)
│   ├── farms/                  (Farm)
│   ├── flocks/                 (Flock)
│   ├── monitoring/             (DailyMonitoring, Measurement)
│   ├── mortality/              (Mortality — annulation RM11 incluse)
│   ├── observations/           (Observation)
│   ├── health/                 (HealthAnalysis, AlertRule, moteur de règles)
│   ├── alerts/                 (Alert, AlertRecipient)
│   ├── recommendations/        (Recommendation)
│   ├── schedules/               (HealthOperation, HealthSchedule)
│   ├── assistance/              (AssistanceRequest, AssistanceResponse)
│   ├── education/               (ContentCategory, EducationalContent)
│   ├── notifications/           (Notification)
│   ├── sync/                    (SynchronizationLog, endpoints push/pull)
│   ├── audit/                   (AuditLog)
│   └── ml/                      (V2+ uniquement — modèles ML, features, entraînement, inférence)
│
└── tests/                        (ou tests/ par app, convention pytest-django)
```

Chaque app suit une structure interne homogène :
```text
apps/mortality/
├── models.py
├── serializers.py
├── views.py            (ViewSets DRF)
├── permissions.py       (Permission classes ≈ Policies Laravel)
├── services.py          (logique métier : ex. cancel_mortality(), transaction + verrou RM4/RM11)
├── signals.py            (déclenche l'analyse sanitaire après création/annulation)
├── urls.py
├── admin.py               (enregistrement Django Admin si pertinent)
└── tests.py (ou tests/)
```

**Note d'adaptation** : ceci remplace la structure `Domain/Application/Infrastructure/Http` proposée en V0 (inspirée DDD/Laravel). Django encourage nativement l'organisation par app fonctionnelle plutôt que par couche technique — c'est **l'équivalent fonctionnel du modular monolith**, pas un abandon du principe (Règle 3 toujours respectée : pas de microservices, pas de sur-ingénierie).

## 5. Back-office administrateur — gain Django (complément à §27/§36 EPIC du cahier final)

**PROPOSITION notable** : contrairement à la V0 où un back-office admin devait être construit spécifiquement (Nova ou custom Laravel), **Django Admin fournit un back-office fonctionnel quasi gratuitement** dès l'enregistrement des modèles (`admin.py`). Ceci réduit significativement l'effort de l'EPIC "Contenus éducatifs & Back-office admin" (§36 du cahier final) : gestion des `EducationalContent`, `AlertRule` (activation/seuils), et consultation des `AuditLog` peuvent être opérationnelles en Django Admin dès la Phase 2, avant même que l'API mobile correspondante soit terminée.


## 6. Modèle de données — remplace §18 (schéma inchangé, ORM différent)

Le **schéma PostgreSQL reste strictement identique** (tables, colonnes, contraintes, index détaillés dans le cahier final §18 et le cahier technique initial §17) — le choix de Django ne change ni les entités ni les règles métier RM1-RM12. Seule la couche ORM change.

### Exemple de modèle Django (équivalent du modèle Eloquent `Flock` du cahier initial)

```python
import uuid
from django.db import models
from django.core.validators import MinValueValidator

class Flock(models.Model):
    class Sex(models.TextChoices):
        MALE = "male", "Mâle"
        FEMALE = "female", "Femelle"
        MIXED = "mixed", "Mixte"

    class Status(models.TextChoices):
        ACTIVE = "active", "Actif"
        CLOSED = "closed", "Clôturé"

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    farm = models.ForeignKey("farms.Farm", on_delete=models.CASCADE, related_name="flocks")
    reference = models.CharField(max_length=50)
    breed = models.CharField(max_length=100, blank=True)
    sex = models.CharField(max_length=10, choices=Sex.choices, default=Sex.MIXED)
    initial_count = models.PositiveIntegerField(validators=[MinValueValidator(1)])
    current_count = models.PositiveIntegerField()
    arrival_date = models.DateField()
    end_date = models.DateField(null=True, blank=True)
    status = models.CharField(max_length=10, choices=Status.choices, default=Status.ACTIVE)
    client_uuid = models.UUIDField(unique=True)
    sync_status = models.CharField(max_length=10, default="synced")
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        constraints = [
            models.CheckConstraint(
                check=models.Q(current_count__lte=models.F("initial_count")),
                name="flock_current_count_lte_initial",
            ),
            models.UniqueConstraint(fields=["farm", "reference"], name="unique_flock_reference_per_farm"),
        ]
        indexes = [models.Index(fields=["farm", "status"])]

    @property
    def mortality_rate(self) -> float:
        if self.initial_count == 0:
            return 0.0
        return round((self.initial_count - self.current_count) / self.initial_count * 100, 2)
```

### Modèle `Mortality` avec annulation tracée (RM11 — équivalent Django)

```python
class Mortality(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    flock = models.ForeignKey("flocks.Flock", on_delete=models.CASCADE, related_name="mortalities")
    date = models.DateField()
    dead_count = models.PositiveIntegerField(validators=[MinValueValidator(1)])
    presumed_cause = models.CharField(max_length=150, blank=True)
    notes = models.TextField(blank=True)
    cancelled_at = models.DateTimeField(null=True, blank=True)
    cancel_reason = models.CharField(max_length=255, blank=True)
    client_uuid = models.UUIDField(unique=True)
    sync_status = models.CharField(max_length=10, default="pending")
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        indexes = [models.Index(fields=["flock", "date"])]

    objects = models.Manager()

    class ActiveManager(models.Manager):
        def get_queryset(self):
            return super().get_queryset().filter(cancelled_at__isnull=True)

    active = ActiveManager()   # Mortality.active.all() exclut les saisies annulées du moteur de règles
```

### Migrations Django (remplace §18 "ordre des migrations")

Contrairement à Laravel où les migrations sont écrites et ordonnées manuellement, **Django génère les migrations automatiquement** (`python manage.py makemigrations`) à partir des modèles, avec détection des dépendances de FK. L'ordre logique reste cependant identique à celui du cahier initial :

```text
accounts     : 0001_initial (User, profils)
farms        : 0001_initial (Farm) — dépend de accounts
flocks       : 0001_initial (Flock) — dépend de farms
schedules    : 0001_initial (HealthOperation)
monitoring   : 0001_initial (DailyMonitoring, Measurement) — dépend de flocks
mortality    : 0001_initial (Mortality) — dépend de flocks
observations : 0001_initial (Observation) — dépend de flocks
health       : 0001_initial (HealthAnalysis, AlertRule) — dépend de flocks
alerts       : 0001_initial (Alert, AlertRecipient) — dépend de health, accounts
recommendations : 0001_initial (Recommendation, AlertRecommendation) — dépend de alerts
schedules    : 0002_health_schedule (HealthSchedule) — dépend de flocks, schedules
assistance   : 0001_initial (AssistanceRequest, AssistanceResponse) — dépend de accounts, flocks
education    : 0001_initial (ContentCategory, EducationalContent)
notifications: 0001_initial (Notification) — dépend de accounts
audit        : 0001_initial (AuditLog) — dépend de accounts
sync         : 0001_initial (SynchronizationLog) — dépend de accounts
```

**Note** : Django ne crée pas de table `personal_access_tokens` (spécifique Sanctum) ; `simplejwt` ne persiste pas les tokens en base par défaut (JWT stateless), ce qui **simplifie légèrement le schéma** par rapport à la V0 — à compenser par une gestion de blacklist des refresh tokens si la révocation par appareil (§20 du cahier final) doit être garantie (`django-rest-framework-simplejwt` propose un module `token_blacklist` pour cela).


## 7. API REST — remplace §19 (endpoints inchangés, implémentation DRF)

La liste complète des endpoints (`/api/v1/...`) définie dans le cahier final (§19 et son delta) **reste strictement valable** — méthodes HTTP, rôles autorisés, codes de réponse. Seule l'implémentation change.

### Exemple équivalent — `POST /api/v1/flocks/{flock}/mortalities` (DRF)

```python
# apps/mortality/serializers.py
from rest_framework import serializers
from .models import Mortality

class MortalityCreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = Mortality
        fields = ["client_uuid", "date", "dead_count", "presumed_cause", "notes"]

    def validate_date(self, value):
        from django.utils import timezone
        if value > timezone.now().date():
            raise serializers.ValidationError("La date ne peut pas être future.")
        return value
```

```python
# apps/mortality/services.py
from django.db import transaction
from rest_framework.exceptions import ValidationError
from apps.flocks.models import Flock
from apps.audit.services import log_action
from .models import Mortality

@transaction.atomic
def record_mortality(*, flock_id, user, data) -> Mortality:
    flock = Flock.objects.select_for_update().get(id=flock_id)   # verrou pessimiste, équivalent lockForUpdate()

    already_dead = flock.initial_count - flock.current_count
    if already_dead + data["dead_count"] > flock.initial_count:
        raise ValidationError({"dead_count": "La mortalité cumulée dépasserait l'effectif initial du lot."})

    mortality = Mortality.objects.create(flock=flock, **data)
    flock.current_count -= data["dead_count"]
    flock.save(update_fields=["current_count"])

    from apps.health.tasks import analyze_flock
    analyze_flock.delay(str(flock.id))   # tâche Celery asynchrone (voir §3)

    return mortality
```

```python
# apps/mortality/views.py
from rest_framework.viewsets import ModelViewSet
from rest_framework.permissions import IsAuthenticated
from .permissions import IsFlockOwner
from .serializers import MortalityCreateSerializer
from .services import record_mortality

class MortalityViewSet(ModelViewSet):
    serializer_class = MortalityCreateSerializer
    permission_classes = [IsAuthenticated, IsFlockOwner]

    def perform_create(self, serializer):
        record_mortality(flock_id=self.kwargs["flock_pk"], user=self.request.user, data=serializer.validated_data)
```

**Réponses 400/401/403/404/422/500** : DRF ne distingue pas nativement 422 de 400 (contrairement à Laravel) — **PROPOSITION** : configurer un `exception_handler` DRF personnalisé pour renvoyer 422 sur les erreurs de validation métier (`ValidationError`) et conserver 400 pour les payloads malformés, afin de respecter exactement le contrat d'API déjà documenté dans le cahier final.

### Permissions (équivalent des Policies Laravel)

```python
# apps/mortality/permissions.py
from rest_framework.permissions import BasePermission
from apps.flocks.models import Flock

class IsFlockOwner(BasePermission):
    def has_permission(self, request, view):
        flock = Flock.objects.select_related("farm").get(id=view.kwargs["flock_pk"])
        return flock.farm.owner_id == request.user.id and flock.status == "active"
```

### Documentation OpenAPI

`drf-spectacular` génère automatiquement le schéma OpenAPI 3 depuis les serializers/viewsets/permissions — remplace `l5-swagger`, avec un résultat équivalent en sortie (`/api/schema/`, `/api/docs/`).

## 8. Sécurité — ajustements Django (complète §20 du cahier final, ne le remplace pas)

| Thème | Équivalent Django |
|---|---|
| Authentification | `djangorestframework-simplejwt` (access + refresh token), révocation via `token_blacklist` |
| Mots de passe | Hachage PBKDF2 par défaut (Django), **PROPOSITION** : passer à Argon2 (`django.contrib.auth.hashers.Argon2PasswordHasher`, package `argon2-cffi`) |
| Mass assignment | Les serializers DRF exposent explicitement les champs autorisés (`fields = [...]`), équivalent du `$fillable` Laravel |
| SQL injection | ORM Django paramétré nativement, même garantie que Eloquent |
| Rate limiting | `django-ratelimit` ou throttling natif DRF (`AnonRateThrottle`, `UserRateThrottle`) sur `/auth/*` |
| Audit | App `audit` dédiée (inchangée du cahier final §18), `AuditLog` enregistré via signal `post_save`/`post_delete` ou appel explicite dans les services |
| CSRF | Non pertinent pour l'API DRF en mode token (comme pour Sanctum), pertinent uniquement si Django Admin est exposé publiquement (protection native déjà active) |


## 9. Moteur de règles et IA — remplace §29 du cahier final (roadmap IA simplifiée)

Le contenu métier du moteur de règles (§22 du cahier final : normalisation, tendance, `trend_window_days`, `confidence`, RM12 anti-répétition) **reste inchangé** — c'est un choix de conception indépendant du langage. Ce qui change, c'est la simplicité d'évolution vers l'IA :

```text
V1 — Règles métier explicables (Python natif, module apps/health/rules.py)
     ex. pandas pour moyenne mobile : df["water_consumption"].rolling(window=3).mean()
↓
V1.5 — Analyse statistique descriptive (pandas/numpy, dans la même codebase apps/health/)
↓
V2 — Machine Learning supervisé
     Nouvelle app apps/ml/ dans le MÊME projet Django (pas de service séparé comme prévu en V0/FastAPI) :
     - apps/ml/features.py    (extraction des variables depuis les modèles Django existants)
     - apps/ml/train.py        (entraînement scikit-learn, exécuté hors requête HTTP, via commande manage.py)
     - apps/ml/inference.py    (appelé depuis la tâche Celery analyze_flock, en complément du moteur de règles)
     - apps/ml/explain.py      (SHAP, pour respecter l'exigence d'explicabilité — Règle 5)
↓
V3/V4 — Prédiction avancée (reste hautement spéculatif, cf. cahier final §29 — aucune donnée ne permet de l'engager aujourd'hui)
```

**Avantage concret confirmé** : en V2, `apps/ml/inference.py` peut directement requêter les modèles Django (`HealthAnalysis.objects.filter(...)`) sans sérialisation/désérialisation HTTP inter-services, sans dupliquer la logique d'accès aux données, et sans synchroniser deux bases de code (Laravel + FastAPI) à chaque évolution du schéma. C'est le principal gain de la décision Django par rapport à la V0.

**Confirmation inchangée du cahier final** : pas d'IA au MVP (V1) ; le moteur de règles explicable reste la seule source d'alerte tant que le volume de données réel n'est pas confirmé (§29 du cahier final, non modifié sur le fond).

## 10. Tests — ajustement (complète §37 du cahier final)

| V0 (Laravel) | Django |
|---|---|
| Pest/PHPUnit | **pytest + pytest-django** (ou `django.test.TestCase`) |
| Factories (Laravel Factories) | **`factory_boy`** (équivalent direct) |
| Tests Feature (API) | **`APITestCase` (DRF) ou `pytest` + `APIClient`** |

Exemple équivalent du test RM4 déjà présenté dans le cahier final (§33 audit), traduit :

```python
import pytest
from rest_framework.test import APIClient
from apps.flocks.tests.factories import FlockFactory
from apps.accounts.tests.factories import FarmerFactory

@pytest.mark.django_db
def test_rejects_mortality_exceeding_flock_initial_count():
    farmer = FarmerFactory()
    flock = FlockFactory(farm__owner=farmer, initial_count=100, current_count=3)
    client = APIClient()
    client.force_authenticate(user=farmer)

    response = client.post(
        f"/api/v1/flocks/{flock.id}/mortalities",
        {"client_uuid": "...", "date": "2026-08-11", "dead_count": 5},
        format="json",
    )

    assert response.status_code == 422
```

## 11. Déploiement — ajustement (complète §38 du cahier final)

Le principe reste identique (VPS + Docker Compose au MVP, migration vers offre managée en V2+). Le service applicatif change simplement de nature dans `docker-compose.yml` :

```yaml
services:
  app:
    build: ./docker/django
    command: gunicorn config.wsgi:application --bind 0.0.0.0:8000
    depends_on: [postgres, redis]

  celery-worker:
    build: ./docker/django
    command: celery -A config worker -l info
    depends_on: [postgres, redis]

  celery-beat:
    build: ./docker/django
    command: celery -A config beat -l info
    depends_on: [postgres, redis]

  # nginx, postgres, redis : inchangés du cahier final §38
```

**Ajout** par rapport à la V0 : deux services supplémentaires (`celery-worker`, `celery-beat`) pour l'analyse sanitaire asynchrone et les rappels planifiés — remplace le mécanisme Laravel Queue/Scheduler intégré à un seul service `app`. Légère hausse de complexité opérationnelle, compensée par le gain d'homogénéité pour l'IA future (§9).

---

## 12. Synthèse — ce qui change / ce qui ne change pas

| Reste identique (indépendant du backend) | Change (spécifique Django) |
|---|---|
| Schéma PostgreSQL, règles métier RM1-RM12 | ORM (Eloquent → Django ORM) |
| UML de cas d'utilisation et diagramme de classes métier | Organisation en apps Django (vs Domain/Application/Infrastructure) |
| Offline-first (SQLite, UUID, idempotence, sync) | Auth : Sanctum → SimpleJWT |
| Moteur de règles (logique, seuils, anti-faux-positifs) | Validation : FormRequest → Serializers DRF |
| Sécurité (principe d'isolation RM6) | Permissions : Policies → BasePermission DRF |
| Business model, marché, SWOT, MVP, roadmap versions | Tâches planifiées : Laravel Scheduler/Queue → Celery + Celery Beat |
| KPI, critères d'acceptation, DoD | Documentation API : L5-Swagger → drf-spectacular |
| Application Flutter (aucun changement, le mobile ne voit qu'une API REST) | Back-office : à construire (Laravel) → **Django Admin natif quasi gratuit** |
| Roadmap IA (principe V1→V4, garde-fous explicabilité) | Implémentation IA : service séparé (FastAPI) → **app intégrée au même projet Django** |

*Fin de l'addendum. À lire en complément du CAHIER_DES_CHARGES_FINAL_AVICOLE.md, dont il remplace les sections listées en introduction.*
