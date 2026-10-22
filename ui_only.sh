#!/usr/bin/env bash
# Replaced by core.sh (2026-10-22): the daily data pipeline needs airflow-postgres, qdrant and
# mlflow next to the login chain, so "UI only" would stop it. Kept so old notes still work.
exec "$(dirname "$0")/core.sh" "$@"
