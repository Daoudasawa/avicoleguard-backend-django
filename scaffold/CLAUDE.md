# CLAUDE.md — AvicoleGuard

Ce fichier est lu automatiquement par Claude Code au démarrage de chaque session dans ce dépôt. Il contient le contexte permanent du projet. Les documents de spécification complets (non répétés ici en détail) doivent être placés à la racine du dépôt sous `docs/` :

- `docs/CAHIER_DES_CHARGES_FINAL_AVICOLE.md` — spécification fonctionnelle et technique de référence
- `docs/RAPPORT_AUDIT_AVICOLE.md` — historique des décisions d'audit
- `docs/ADDENDUM_TECHNIQUE_DJANGO.md` — détail de l'implémentation Django (remplace les sections Laravel du cahier)
- `docs/SUIVI_DEVELOPPEMENT_AVICOLEGUARD.xlsx` — backlog et suivi de sprint

**Avant toute tâche de développement non triviale, lire le(s) document(s) pertinent(s) ci-dessus plutôt que de deviner une règle métier ou un endpoint.**

---

## 1. Résumé du projet

AvicoleGuard : application mobile (Flutter, offline-first) + API backend (Django/DRF) d'accompagnement des acteurs avicoles au Burkina Faso — éleveurs, vétérinaires, techniciens, administrateurs, responsables de coopérative. Objectif central : suivi structuré des lots, détection d'anomalies sanitaires via un moteur de règles explicable (**jamais** d'IA ni de diagnostic automatique en V1), génération d'alertes/recommandations, et mise en relation avec des professionnels.

## 2. Stack

| Composant | Choix |
|---|---|
| Backend | Python 3.12+, Django 5.x, Django REST Framework |
| Auth | `djangorestframework-simplejwt` (access + refresh, blacklist activée) |
| Base de données | PostgreSQL |
| Tâches async/planifiées | Celery + Celery Beat, broker Redis |
| Doc API | drf-spectacular (OpenAPI 3) |
| Tests | pytest + pytest-django + factory_boy |
| Mobile | Flutter/Dart, stockage local SQLite via Drift |
| Infra | Docker Compose (app, celery-worker, celery-beat, postgres, redis, nginx) |

Ne jamais proposer PostGIS, microservices, ou un service ML séparé : hors périmètre MVP (voir §9).

## 3. Structure du dépôt (backend)

```
avicoleguard/
├── config/                 # settings, urls, celery.py
├── apps/
│   ├── accounts/            # User custom + profils farmer/vet/technician/admin/coop
│   ├── farms/
│   ├── flocks/
│   ├── monitoring/           # DailyMonitoring, Measurement
│   ├── mortality/             # Mortality (+ annulation RM11)
│   ├── observations/
│   ├── health/                 # HealthAnalysis, AlertRule, moteur de règles
│   ├── alerts/
│   ├── recommendations/
│   ├── schedules/                # HealthOperation, HealthSchedule
│   ├── assistance/
│   ├── education/
│   ├── notifications/
│   ├── sync/                       # endpoints push/pull offline
│   ├── audit/                       # AuditLog
│   └── ml/                            # V2+ uniquement, ne pas créer avant validation §9
└── tests/ (ou tests/ par app)
```

Chaque app suit ce patron interne : `models.py`, `serializers.py`, `views.py` (ViewSets DRF), `permissions.py`, `services.py` (logique métier), `signals.py`, `urls.py`, `admin.py`, `tests.py`.

**Toute logique métier non triviale va dans `services.py`, jamais directement dans une vue.** Les vues restent minces (validation → appel service → sérialisation de la réponse).

## 4. Règles métier — À NE JAMAIS VIOLER

Ces règles sont contractuelles (issues du cahier des charges §13). Toute PR qui les enfreint doit être rejetée.

- **RM1-RM3** : `dead_count > 0` ; `0 <= current_count <= initial_count` en permanence.
- **RM4** : mortalité cumulée sur un lot `<= initial_count`, garantie par transaction + `select_for_update()` (verrou pessimiste). Ne jamais valider une mortalité hors transaction.
- **RM6 — PRIORITÉ ABSOLUE** : isolation stricte des données par éleveur. Toute ressource exposée par l'API doit avoir une `Permission` DRF qui vérifie l'ownership (via `flock.farm.owner_id == request.user.id`, ou l'affectation pour vétérinaire/technicien). Ne jamais exposer un endpoint sans permission explicite.
- **RM7** : aucune nouvelle saisie (suivi/mortalité/observation) sur un lot `status='closed'`.
- **RM8** : une `Alert` n'est créée que par le moteur de règles (`apps/health`), jamais saisie manuellement.
- **RM9** : toute recommandation générée automatiquement doit porter la mention "signal détecté automatiquement, ne remplace pas un avis vétérinaire" tant qu'un professionnel ne l'a pas validée. **Ne jamais utiliser le mot "diagnostic" pour une sortie automatique**, dans le code, les messages d'erreur, l'UI ou les commentaires.
- **RM10** : toute opération de synchronisation offline est idempotente (upsert par `client_uuid`, jamais un `create` brut sur un endpoint de sync).
- **RM11** : correction/annulation = toujours `cancelled_at` + `cancel_reason` + recalcul (`current_count`, etc.) + entrée `AuditLog`. **Jamais de suppression physique (`DELETE`) sur une donnée terrain saisie par un utilisateur.**
- **RM12** : anti-répétition d'alerte — pas de nouvelle alerte pour la même règle+lot dans une fenêtre de 24h sauf aggravation du score.

## 5. Conventions API

- Préfixe `/api/v1/`, ViewSets DRF, pagination standard (`page`, `per_page`, max 50).
- Erreurs de validation métier → **422** (configurer un `exception_handler` DRF dédié, DRF ne le fait pas nativement — ne pas laisser une violation de règle métier remonter en 400 ou 500).
- Chaque nouvel endpoint doit être documenté via drf-spectacular (annotations `@extend_schema` si le nom/type ne suffit pas à l'auto-générer correctement).
- Toute création de saisie terrain (`daily-monitorings`, `mortalities`, `observations`) accepte et exige un `client_uuid` (UUID v4 généré côté client) — c'est la clé d'idempotence de la synchronisation offline.

## 6. Offline-first — points de vigilance pour le code mobile (Flutter)

- Toute saisie terrain s'écrit d'abord en local (SQLite/Drift, `sync_status=pending`), jamais en attente bloquante d'un appel réseau.
- Les identifiants sont générés côté client (UUID v4) à la création — ne jamais attendre un ID serveur pour permettre la navigation/l'usage local.
- Le `SyncQueueWorker` doit gérer : retry avec backoff exponentiel plafonné, détection de conflit (comparaison de version), statuts `pending/syncing/synced/failed/conflict/cancelled_pending`.
- Ne jamais faire disparaître silencieusement une saisie en échec de synchronisation : le statut `failed` doit rester visible et actionnable par l'utilisateur.

## 7. Tests

- `pytest-django`, factories via `factory_boy` (une factory par modèle dans `apps/<app>/tests/factories.py`).
- Toute nouvelle règle métier (§4) doit avoir un test dédié qui la viole intentionnellement et vérifie le rejet (ex. dépassement `initial_count`, accès cross-éleveur → 403).
- Tests de sécurité obligatoires pour toute nouvelle ressource : accès refusé à un utilisateur non propriétaire, accès refusé sans authentification.
- Tests de synchronisation obligatoires pour tout nouvel endpoint `sync/*` : rejeu du même `client_uuid` → un seul enregistrement en base.
- Commande : `pytest` (config dans `pytest.ini` / `pyproject.toml`, DB de test PostgreSQL dédiée).

## 8. Commandes utiles

```bash
# Environnement de dev complet
docker compose up -d

# Migrations
python manage.py makemigrations
python manage.py migrate

# Lancer les tests
pytest
pytest apps/mortality -v          # une seule app

# Lint / format (à harmoniser avec l'équipe — proposition)
ruff check .
ruff format .

# Créer un superuser (accès Django Admin)
python manage.py createsuperuser

# Worker Celery (analyse sanitaire asynchrone, rappels planifiés)
celery -A config worker -l info
celery -A config beat -l info

# Génération du schéma OpenAPI
python manage.py spectacular --file schema.yaml
```

## 9. Ce qui est explicitement HORS PÉRIMÈTRE du MVP (V1)

Ne pas implémenter sans validation explicite du porteur de projet, même si le cahier des charges en parle en roadmap :
- Module finance (`transactions`) — table volontairement absente du schéma MVP.
- IA/ML (`apps/ml/`) — reporté à la V2, conditionné à un volume de données réel confirmé.
- PostGIS / recherche géospatiale avancée — coordonnées `latitude`/`longitude` simples suffisent.
- Marketplace, affectation automatique des demandes d'assistance, rappels automatiques de calendrier sanitaire (V1.5), reporting agrégé coopérative (V1.5).
- Microservices — tout reste dans le même projet Django (apps), voir §9 de l'addendum technique.

## 10. Definition of Done (rappel — détail complet dans le cahier §41)

Une fonctionnalité n'est terminée que si : code + tests passants (Unit/Feature, Security/Sync si applicable) + Permission DRF vérifiée + doc API à jour + comportement offline défini si saisie terrain + wording conforme RM9 + migration rejouable sur base vierge + audit log si action sensible.

## 11. Style de communication attendu de Claude Code sur ce projet

- Toujours signaler explicitement si une demande de fonctionnalité entre en conflit avec une règle métier (§4) ou le périmètre MVP (§9), plutôt que de l'implémenter silencieusement.
- Pour toute ambiguïté sur une règle de gestion, se référer à `docs/CAHIER_DES_CHARGES_FINAL_AVICOLE.md` avant de faire une hypothèse.
- Préférer des migrations Django auto-générées (`makemigrations`) revues manuellement plutôt qu'écrites à la main.
