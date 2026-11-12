# DOCUMENT 1 — RAPPORT D'AUDIT
## Audit critique du cahier technique V0 (AvicoleGuard)

**Document audité** : *CAHIER_TECHNIQUE_AVICOLE_LARAVEL.md* (version V0, produite lors de l'itération précédente de ce travail).
**Méthode** : revue par un comité pluridisciplinaire (produit, architecture, Laravel, Flutter, PostgreSQL, UX, aviculture, santé animale, IA, cybersécurité, DevOps, offline-first, business model, transformation numérique Afrique, qualité logicielle).

---

## 1. Synthèse

La V0 est **techniquement solide** sur l'architecture backend (Laravel modular monolith, schéma PostgreSQL, offline-first) et respecte globalement la Règle 5 (pas de diagnostic automatique). Elle présente cependant des **faiblesses produit** : personas trop génériques, absence de distinction claire entre segments d'éleveurs, moteur de règles insuffisamment détaillé sur la lutte contre les faux positifs, business model non challengé, étude de marché quasi vide (alors que des sources publiques existent), et plusieurs zones de **sur-ambition pour un MVP** (module finance, PostGIS évoqué même si écarté, calendrier sanitaire avec rappels dès le MVP).

---

## 2. Problèmes détectés, contradictions, ambiguïtés

| # | Constat | Type | Sévérité |
|---|---|---|---|
| A1 | Le problème métier est réduit à « prévenir les maladies et réduire la mortalité » sans distinguer causes (manque de suivi, détection tardive, accès limité aux professionnels, mauvaises pratiques) de conséquences (pertes économiques) | Ambiguïté | Élevée |
| A2 | Les personas (« Amidou », « Dr. Sanou », « Fatou ») sont uniques par rôle : aucune distinction éleveur débutant / expérimenté / professionnel, alors que leurs besoins numériques et leur fréquence d'usage diffèrent fortement | Fonctionnalité manquante | Élevée |
| A3 | Le responsable de coopérative est absent des acteurs alors que le business model V0 mise en partie sur le B2B coopératives | Acteur oublié | Moyenne |
| A4 | Le moteur de règles ne précise pas comment éviter les faux positifs (tendances, périodes glissantes, niveau de confiance) — un seul seuil brut par règle | Problème de conception | Élevée |
| A5 | Le calendrier sanitaire avec rappels est classé SHOULD HAVE dans la V0, mais son moteur de notification planifiée (Scheduler) ajoute une complexité non négligeable pour un MVP censé démontrer avant tout le flux mortalité→alerte | Fonctionnalité trop ambitieuse pour le MVP | Moyenne |
| A6 | Le module `transactions` (finance) est présent dans le schéma de données dès la V0 alors qu'il est classé COULD HAVE — la table existe en base sans fonctionnalité MVP qui l'utilise (incohérence cahier ↔ base) | Incohérence BDD/fonctionnalités | Moyenne |
| A7 | Aucune politique explicite de suppression de compte / droit à l'oubli n'est définie (la V0 ne parle que de désactivation logique) | Règle métier absente | Moyenne |
| A8 | Le choix Firebase Cloud Messaging pour le push est présenté comme "DÉCISION PROPOSÉE" mais aucune alternative offline-friendly (notification différée locale) n'est envisagée pour les longues périodes sans réseau | Problème offline | Moyenne |
| A9 | L'étude de marché V0 est presque vide ("Je ne sais pas") alors que des données publiques (FAO, CCI-BF, Agence Ecofin) existent et permettent de sourcer une partie du contexte | Fonctionnalité manquante (rigueur) | Élevée |
| A10 | Aucun concurrent n'est identifié en V0 alors que plusieurs applications de gestion avicole existent, dont au moins une conçue spécifiquement pour l'Afrique subsaharienne | Fonctionnalité manquante | Élevée |
| A11 | Le rôle "Service de notification" et "Service IA" apparaissent comme acteurs UML dans le document source (`volaile.docx`) mais ne sont pas des acteurs humains — leur statut d'acteur système vs composant technique n'est jamais clarifié | Ambiguïté UML | Faible |
| A12 | Aucun mécanisme de suppression/correction d'une saisie erronée (mortalité saisie deux fois par erreur, faute de frappe) n'est prévu — seule la création est couverte | Cas d'utilisation incomplet | Moyenne |
| A13 | La politique de rétention des données et le RGPD-like local ne sont qu'évoqués ("à valider"), alors qu'il s'agit d'un point bloquant pour toute présentation à des investisseurs/partenaires institutionnels | Risque réglementaire | Moyenne |
| A14 | Aucun KPI n'est défini en V0 (le document s'arrête aux critères d'acceptation fonctionnels) — impossible de savoir si le produit "fonctionne" une fois déployé | Fonctionnalité manquante | Élevée |
| A15 | Le backlog V0 est une liste plate priorisée, pas structuré en EPIC/US/tâches — insuffisant pour un chiffrage projet | Qualité de spécification | Moyenne |

---

## 3. Fonctionnalités : validation par statut

| Élément | Statut |
|---|---|
| Gestion exploitations/lots/suivi/mortalité/observations | **VALIDÉ** |
| Moteur de règles explicable (pas d'IA en V1) | **VALIDÉ** dans le principe — **À MODIFIER** dans le détail (gestion des faux positifs, tendances) |
| Offline-first (UUID, idempotence, retry, conflits) | **VALIDÉ** dans le principe — **À CONFIRMER** le chiffrement local (non tranché en V0) |
| Isolation des données par éleveur (Policies) | **VALIDÉ** |
| Assistance vétérinaire/technique | **VALIDÉ**, affectation manuelle uniquement — **À CONFIRMER** avec réseau de professionnels réel |
| Calendrier sanitaire avec rappels | **À REPORTER** en partie (planification simple = MVP ; rappels automatiques = V1.5) |
| Contenus éducatifs | **VALIDÉ** en lecture seule pour le MVP |
| Module finance (dépenses/ventes) | **À REPORTER** (déjà identifié COULD HAVE en V0, confirmé par cet audit) |
| Marketplace | **À REPORTER**, cohérent avec V0 |
| PostGIS / géolocalisation avancée | **À SUPPRIMER** du MVP, confirmé, coordonnées simples suffisent |
| IA prédictive | **À REPORTER**, cohérent avec V0, roadmap V1→V4 à préciser (voir Document 2 §27) |
| Vision coopérative multi-exploitations | **À REPORTER**, mais le **rôle** responsable de coopérative doit être ajouté dès la modélisation des acteurs (impact faible sur le schéma, évite une refonte ultérieure) |
| Correction/suppression d'une saisie erronée | **À AJOUTER** au MVP (absente de la V0, nécessaire à l'usage réel quotidien) |
| KPI produit/aviculture/business | **À AJOUTER** (absent de la V0) |

---

## 4. Risques complémentaires identifiés par l'audit

| Risque | Probabilité | Impact | Niveau | Mitigation |
|---|---|---|---|---|
| Faux positifs répétés du moteur de règles → désengagement des éleveurs (fatigue d'alerte) | Moyenne-Élevée | Élevé | **Élevé** | Introduire tendances/périodes glissantes et niveau de confiance (Document 2 §20) plutôt que des seuils bruts isolés |
| Absence de mécanisme de correction de saisie → perte de confiance dans les données historisées | Moyenne | Moyen | Moyen | Ajouter une fonctionnalité de correction/annulation encadrée (traçée, jamais une suppression silencieuse) |
| Confusion possible entre "niveau de risque élevé" et "diagnostic" dans l'esprit d'un éleveur peu technophile | Moyenne | Élevé | **Élevé** | Renforcer l'UX (couleurs, wording testés avec de vrais éleveurs), pas seulement le wording textuel déjà prévu en V0 |
| Dépendance à un unique canal de push (FCM) dans un contexte de connectivité intermittente | Moyenne | Faible-Moyen | Faible-Moyen | Compléter par des rappels locaux programmés côté app (notifications système sans réseau) |
| Absence de données de marché sourcées → crédibilité réduite auprès de partenaires/investisseurs | Élevée (avant cet audit) | Moyen | Moyen | Corrigé dans le Document 2 §26 (sources FAO/CCI-BF/Agence Ecofin citées, avec fiabilité indiquée) |

---

## 5. Recommandations de l'audit (à reporter dans le cahier final)

1. Enrichir les personas par segment d'éleveur (débutant/expérimenté/professionnel) et ajouter le responsable de coopérative comme acteur, même si son usage complet est reporté.
2. Faire évoluer le moteur de règles pour intégrer tendances et niveau de confiance, avec un mécanisme explicite de limitation des faux positifs.
3. Ajouter une fonctionnalité de correction/annulation tracée des saisies (mortalité, suivi, observation).
4. Sourcer l'étude de marché avec les données publiques disponibles (FAO, CCI-BF, Agence Ecofin, Inter-réseaux) et identifier les solutions concurrentes existantes (123POULTRY, G-Avicole, Easy Poultry Manager, Aniprev).
5. Définir des KPI produit/aviculture/business, sans valeurs cibles inventées.
6. Restructurer le backlog en EPIC/User Stories avec sous-tâches backend/mobile/tests.
7. Ajouter une Definition of Done explicite.
8. Clarifier la politique de suppression de compte (droit à l'oubli) au-delà de la simple désactivation logique.
9. Reporter explicitement le calendrier sanitaire "avec rappels automatiques" en V1.5, ne garder en MVP que la planification + marquage manuel "effectué".
10. Retirer la table `transactions` du schéma MVP (elle réapparaîtra en V1.5/V2 avec le module finance) pour garantir la cohérence cahier ↔ base.

---

*Fin du rapport d'audit. Les éléments ci-dessus sont intégrés dans le Document 2 — Cahier des charges final.*
