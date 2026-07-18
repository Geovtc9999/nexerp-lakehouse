# Soda — qualité de données de la base source

Checks Soda Core exécutés à la demande contre la base `nexerp` (schéma `nexerp`),
avec le rôle **lecture seule** `fabric_app`.

## Prérequis réseau
Le runner doit atteindre le conteneur PostgreSQL source `ysprg0oqzl86voh0kv0u6b6q`.
Celui-ci vit sur son réseau de stack Coolify — le rejoindre au réseau `coolify`
(ou lancer le scan attaché au réseau du conteneur source) avant exécution.

## Lancer un scan (conteneur jetable)
```bash
docker run --rm \
  --network coolify \
  -v /data/fabric/cognitive/soda:/sodacl \
  -e PG_HOST=ysprg0oqzl86voh0kv0u6b6q \
  -e PG_PORT=5432 \
  -e PG_USER=fabric_app \
  -e PG_PASSWORD='<PG_FABRIC_SOURCE_PASSWORD>' \
  -e PG_DB=nexerp \
  python:3.11-slim \
  sh -c "pip install -q soda-core-postgres==3.3.* && \
         soda scan -d nexerp -c /sodacl/configuration.yml /sodacl/checks.yml"
```
> ⚠️ Image **python:3.11**-slim (pas 3.12) : soda-core 3.3 importe `distutils`, supprimé en 3.12.
> Le mot de passe `fabric_app` (source) est dans Infisical `/fabric/postgres/`.
> Ne jamais le mettre en dur dans le repo.

## Ce que couvrent les checks (`checks.yml`)
- **Unicité & complétude des PK** sur toutes les tables à clé.
- **Intégrité référentielle** (détection d'orphelins) : knowledge_chunk→knowledge_source,
  message→thread, thread→organization/app_user, agent/skill→organization,
  agent_skill→agent/skill, memory→agent, deliverable→thread, usage_ledger→organization,
  app_user/perimeter→organization, user_perimeter→app_user/perimeter.
- **Validité** : `confidence` ∈ [0,1] (message/thread/audit_log), `cost_eur`/`tokens` ≥ 0,
  `budget_monthly_eur` ≥ 0, `install_count` ≥ 0.
- **Unicité métier** : `app_user.email`, `audit_log.hash`.
- **Audit anti-falsification** : la chaîne de hash de `audit_log` (chaque ligne chaîne le
  hash précédent) — `hash_chain_breaks = 0`.
- **Schéma** : colonnes requises présentes sur `organization`.

Tables actuellement vides (team, project, integration, skill_version…) : pas de check
`row_count > 0` pour éviter les faux échecs — à ajouter quand elles seront alimentées.
