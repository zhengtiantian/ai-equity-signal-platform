#!/usr/bin/env bash
# Start only what quant_ui needs to log in and show its pages, and stop everything else.
#
#   quant_ui -> quant_api -> mysql, mongodb, keycloak, kafka     (6 containers)
#   (quant_api does not start without kafka: "No resolvable bootstrap urls")
#
# The portfolio, global markets and daily briefs are served by quant_ai on the host, which
# runs without Docker. The other services (kafka-ui, airflow, mlflow, qdrant, quant_data,
# quant-ai) are "restart: unless-stopped", so once stopped here they stay stopped even when
# Docker Desktop restarts. Start the full platform with: docker compose up -d
set -euo pipefail
cd "$(dirname "$0")"

# Every data volume (mysql, mongo, kafka, airflow...) is a bind mount on the external disk.
if [ ! -d /Volumes/Data4T/docker-volumes ]; then
  echo "Data4T is not mounted: plug the external disk in first (all container data lives there)." >&2
  exit 1
fi

UI=(mysql mongodb keycloak kafka quant_api quant_ui)
others=$(docker compose config --services | grep -vxF -f <(printf '%s\n' "${UI[@]}") || true)
if [ -n "$others" ]; then
  # Containers created before the compose change still carry "always", which Docker Desktop
  # restarts on every launch; set the policy on the existing containers too.
  # shellcheck disable=SC2086
  ids=$(docker compose ps -a -q $others)
  [ -n "$ids" ] && docker update --restart unless-stopped $ids >/dev/null
  # shellcheck disable=SC2086
  docker compose stop $others
fi
docker compose up -d "${UI[@]}"
echo "quant_ui: http://localhost:18080 (My Holdings, Market Briefs)"
