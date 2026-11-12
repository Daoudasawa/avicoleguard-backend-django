# AvicoleGuard — Backend Django

Squelette de démarrage généré à partir de `docs/ADDENDUM_TECHNIQUE_DJANGO.md` et testé (Django check + makemigrations OK).
**Lire `CLAUDE.md` avant toute contribution** — il contient les règles métier non négociables (RM1-RM12).

## Démarrage rapide

```bash
# 1. Copier la config d'environnement
cp .env.example .env
# éditer .env : mettre un vrai DJANGO_SECRET_KEY, DB_PASSWORD, etc.

# 2. Lancer l'environnement complet (Django + PostgreSQL + Redis + Celery + Nginx)
docker compose up -d --build

# 3. Appliquer les migrations (déjà générées pour accounts/farms/flocks/mortality/audit)
docker compose exec app python manage.py migrate

# 4. Créer un compte admin
docker compose exec app python manage.py createsuperuser

# 5. Vérifier que ça tourne
curl http://localhost:8000/api/docs/    # documentation Swagger (drf-spectacular)
```

Sans Docker (dev local avec PostgreSQL déjà installé) :
```bash
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements-dev.txt
cp .env.example .env   # adapter DB_HOST=localhost
python manage.py migrate
python manage.py runserver
```

## Lancer les tests

```bash
docker compose exec app pytest -v
# ou en local :
pytest -v
```

Le fichier `apps/mortality/tests/test_mortality_rules.py` couvre déjà RM1-RM4, RM7 et RM11 — à prendre comme modèle pour les tests des prochaines apps (voir `docs/SUIVI_DEVELOPPEMENT_AVICOLEGUARD.xlsx`, Sprint 4).

## Ce qui est déjà en place (Sprint 0-1 du suivi de développement)

- [x] Projet Django + 15 apps du modular monolith créées et enregistrées
- [x] `User` custom avec rôles (farmer/veterinarian/technician/cooperative_manager/admin)
- [x] Modèles `Farm`, `Flock`, `Mortality` (avec RM4/RM7/RM11) + migrations générées
- [x] Service `record_mortality` / `cancel_mortality` avec verrou transactionnel (`select_for_update`)
- [x] `AuditLog` + service `log_action`
- [x] Docker Compose complet (app, celery-worker, celery-beat, postgres, redis, nginx)
- [x] DRF + SimpleJWT + drf-spectacular configurés dans `settings.py`
- [x] Tests pytest de base sur les règles métier critiques

## Ce qui reste à faire (voir le backlog complet, onglet "Backlog détaillé")

- Serializers/ViewSets/Permissions réels pour chaque app (squelettes vides créés, à remplir)
- Modèles restants : `DailyMonitoring`, `Observation`, `HealthAnalysis`, `AlertRule`, `Alert`, `Recommendation`, `HealthSchedule`, `AssistanceRequest/Response`, `ContentCategory/EducationalContent`, `Notification`, `SynchronizationLog`
- Moteur de règles (`apps/health`) — voir cahier des charges §22
- Endpoints de synchronisation offline (`apps/sync`) — voir cahier des charges §21
- CI (lint + tests + build image)

## Documentation de référence

Voir `docs/` : cahier des charges final, rapport d'audit, addendum technique Django, suivi de développement (sprints).
