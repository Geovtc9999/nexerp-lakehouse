#!/usr/bin/env bash
# Scan Soda hebdomadaire de la base source (plateforme Bayon MDM).
# Lance un conteneur jetable attaché au réseau propre de la base source
# (la source n'est PAS sur le réseau coolify). Destiné à cron.
#
# Setup serveur :
#   git clone https://github.com/Geovtc9999/nexerp-lakehouse /data/fabric/cognitive
#   printf "PG_FABRIC_SOURCE_PASSWORD='<mdp fabric_app source>'\n" > /data/fabric/cognitive/.soda.env
#   chmod 600 /data/fabric/cognitive/.soda.env
#   chmod +x /data/fabric/cognitive/run-soda-scan.sh
#   ( crontab -l 2>/dev/null; echo "0 6 * * 1 /data/fabric/cognitive/run-soda-scan.sh" ) | crontab -
set -uo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
ENV_FILE="${SODA_ENV_FILE:-$HERE/.soda.env}"
SRC="${SRC_CONTAINER:-ysprg0oqzl86voh0kv0u6b6q}"
LOG_DIR="$HERE/logs"; mkdir -p "$LOG_DIR"
STAMP="$(date +%Y%m%d-%H%M%S)"
LOG="$LOG_DIR/soda-$STAMP.log"

# Mise à jour best-effort des checks depuis le repo (ignore si offline).
git -C "$HERE" pull --quiet 2>/dev/null || true

# Mot de passe source : fichier chmod 600 hors git.
# shellcheck disable=SC1090
[ -f "$ENV_FILE" ] && . "$ENV_FILE"
: "${PG_FABRIC_SOURCE_PASSWORD:?PG_FABRIC_SOURCE_PASSWORD manquant — créer $ENV_FILE}"

# Réseau propre de la base source (résolu dynamiquement à chaque run).
NET="$(docker inspect -f '{{range $k,$v := .NetworkSettings.Networks}}{{$k}} {{end}}' "$SRC" 2>/dev/null | awk '{print $1}')"
[ -n "$NET" ] || { echo "$(date -Iseconds) ERREUR: conteneur source $SRC introuvable" | tee -a "$LOG"; exit 3; }

{
  echo "=== Soda scan $STAMP (source=$SRC net=$NET) ==="
  docker run --rm --network "$NET" -v "$HERE/soda:/sodacl" \
    -e PG_HOST="$SRC" -e PG_PORT=5432 -e PG_USER=fabric_app -e PG_DB=nexerp \
    -e PG_PASSWORD="$PG_FABRIC_SOURCE_PASSWORD" \
    python:3.11-slim \
    sh -c "pip install -q soda-core-postgres==3.3.* && soda scan -d nexerp -c /sodacl/configuration.yml /sodacl/checks.yml"
} >>"$LOG" 2>&1
rc=$?

echo "$(date -Iseconds) soda scan exit=$rc log=$LOG"
grep -E "checks (PASSED|NOT EVALUATED)|failures|error" "$LOG" | tail -3
# Rotation : conserver les 30 derniers logs.
ls -1t "$LOG_DIR"/soda-*.log 2>/dev/null | tail -n +31 | xargs -r rm -f
exit $rc
