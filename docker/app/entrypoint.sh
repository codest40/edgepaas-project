#!/bin/bash
set -euo pipefail

local_env="${1:-prod}"
local_env="${local_env,,}"

TZ="Africa/Lagos"
export TZ

timer=$(date +"%Y:%m:%d_%H:%M:%S")
echo "[ENTRY] $timer Bootstrapping environment..."
source ./bootstrap_env.sh

echo "[ENTRY] $timer Waiting for DB..."
python wait_for_db.py

echo "[ENTRY] Sourcing /tmp DB ENV file..."
source /tmp/db_env.sh

# ----------------------------
# Run Alembic migrations if Postgres is active
# ----------------------------
if [[ "${RUN_MIGRATIONS,,}" == "true" ]]; then
    echo "[ALEMBIC] Running migrations..."
    if ! python -m alembic upgrade head; then
        echo "[ALEMBIC] Migration failed. Resetting..."
        python reset_alembic.py
        echo "[ALEMBIC] Retrying migrations..."
        python -m alembic upgrade head
    fi
else
    echo "[ALEMBIC] Skipping migrations (SQLite or RUN_MIGRATIONS=false)"
fi

# Decide Portt
PORT="${CONTAINER_PORT:-80}"
if [[ "$local_env" == "dev" ]]; then
    PORT="${CONTAINER_PORT:-8090}"
fi

# ----------------------------
# Final summary
# ----------------------------
echo ""
echo "=============================================="
echo "[SUMMARY] Deployment Environment Ready"
echo "  ENVIRONMENT       : $local_env"
echo "  FINAL_DB_MODE     : ${FINAL_DB_MODE:-unknown}"
echo "  DATABASE_URL      : ${DATABASE_URL:-unknown}"
echo "  RUN_MIGRATIONS    : ${RUN_MIGRATIONS:-false}"
echo "  FASTAPI_PORT      : $PORT"
echo "=============================================="
echo ""

# ----------------------------
# Start FastAPI
# ----------------------------
echo "[START] Starting FastAPI on port $PORT..."
exec uvicorn main:app --host 0.0.0.0 --port "$PORT"
