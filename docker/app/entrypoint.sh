#!/bin/bash
set -e

timer=$(date +"%H:%M:%S")
echo "Current time: $timer"

echo "[START(Entry) $timer] Waiting for DB..."
python wait_for_db.py

# Run Alembic only if RUN_MIGRATIONS is set to true
echo "Detected Env RUN_MIGRATIONS: $RUN_MIGRATIONS"
echo "Detected Env DATABASE_URL: $DATABASE_URL"
echo "Detected Env OPENWEATHER KEY: $OPENWEATHER_API_KEY"
echo "Detected Env CONTAINER_PORT: $CONTAINER_PORT"
echo "Detected Env ACTIVE_PORT: $active_port"

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

echo "[START(Entry) $timer] Starting FastAPI..."
exec uvicorn main:app --host 0.0.0.0 --port ${CONTAINER_PORT:-80}
