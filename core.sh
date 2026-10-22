#!/usr/bin/env bash
# Start the platform's always-on core and stop everything else.
#
#   login chain : mysql, mongodb, keycloak, kafka, quant_api, quant_ui
#                 (quant_api does not start without kafka: "No resolvable bootstrap urls")
#   data pipeline: airflow-postgres (the host Airflow scheduler's metadata DB), qdrant (news
#                 vectors), mlflow (weekly training); mongodb and mysql are shared with the above
#
# The Airflow scheduler itself runs on the host (launchd com.quant.airflow-scheduler) and
# crash-loops while airflow-postgres is down, so the daily pipeline needs this core running.
# The portfolio, global markets and daily briefs run in quant_ai on the host without Docker.
# Not started: kafka-ui, airflow-webserver, quant_data / quant-ai containers (their work runs
# on the host). Start the full platform with: docker compose up -d
set -euo pipefail
cd "$(dirname "$0")"

# Every data volume (mysql, mongo, kafka, airflow...) is a bind mount on the external disk.
if [ ! -d /Volumes/Data4T/docker-volumes ]; then
  echo "Data4T is not mounted: plug the external disk in first (all container data lives there)." >&2
  exit 1
fi

CORE=(mysql mongodb keycloak kafka quant_api quant_ui airflow-postgres qdrant mlflow)
others=$(docker compose config --services | grep -vxF -f <(printf '%s\n' "${CORE[@]}") || true)
if [ -n "$others" ]; then
  # Containers created before the compose change may still carry "always", which Docker
  # Desktop restarts on every launch; set the policy on the existing containers too.
  # shellcheck disable=SC2086
  ids=$(docker compose ps -a -q $others)
  [ -n "$ids" ] && docker update --restart unless-stopped $ids >/dev/null
  # shellcheck disable=SC2086
  docker compose stop $others
fi
docker compose up -d "${CORE[@]}"
# The core comes back by itself whenever Docker Desktop starts.
# shellcheck disable=SC2046
docker update --restart always $(docker compose ps -a -q "${CORE[@]}") >/dev/null
# nginx in quant_ui resolves quant_api once, at its own start: if quant_api was still
# restarting then, every /api call answers 502. Wait for quant_api, then restart quant_ui.
for _ in $(seq 1 60); do
  [ "$(docker inspect -f '{{.State.Health.Status}}' quant_api 2>/dev/null)" = healthy ] && break
  sleep 3
done
docker compose restart quant_ui >/dev/null
echo "core up: quant_ui http://localhost:18080 · Airflow metadata DB 127.0.0.1:25432 · qdrant 26333 · mlflow 15050"
