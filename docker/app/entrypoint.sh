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

# ----------------------------
# Start FastAPI
# ----------------------------
PORT="${CONTAINER_PORT:-80}"
if [[ "$local_env" == "dev" ]]; then
    PORT="${CONTAINER_PORT:-8090}"
fi

echo "[START] Starting FastAPI on port $PORT..."
exec uvicorn main:app --host 0.0.0.0 --port "$PORT"
