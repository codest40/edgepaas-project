#!/bin/bash
set -e

local_env=${1:-prod}
local_env="${local_env,,}"

TZ="Africa/Lagos"
export TZ

timer=$(date +"%Y:%m:%d_%H:%M:%S")
echo "Current time: $timer"

echo "[START(Entry) $timer] Waiting for DB..."
python wait_for_db.py

# Run Alembic only if RUN_MIGRATIONS is set to true
echo "Detected Env RUN_MIGRATIONS: $RUN_MIGRATIONS"

if [ "${RUN_MIGRATIONS,,}" = "true" ]; then
    echo "[START(Entry) $timer] Running Alembic migrations..."
    if ! python -m alembic upgrade head; then
      echo "[ERROR] Alembic failed. Resetting migrations..."
      ./reset_alembic.sh
      echo "[RETRY(Entry) $timer] Running Alembic migrations again..."
      python -m alembic upgrade head
    fi
else
    echo "[SKIP(Entry) $timer] Alembic migrations (RUN_MIGRATIONS=${RUN_MIGRATIONS})"
fi

if  [[  "$local_env" == "dev" ]]; then
  echo "[START(Entry) $timer] Starting FastAPI On Laptop Environment Using Port ${CONTAINER_PORT:-8090}....."
  exec uvicorn main:app --host 0.0.0.0 --port ${CONTAINER_PORT:-8090}
else
  echo "[START(Entry) $timer] Starting FastAPI On Remote Usinng Port ${CONTAINER_PORT:-80}....."
  exec uvicorn main:app --host 0.0.0.0 --port ${CONTAINER_PORT:-80}
fi
