#!/bin/bash
set -e

echo "[START(Entry)] Waiting for DB..."
python wait_for_db.py

# Run Alembic only if RUN_MIGRATIONS is set to true
echo "Detected Env RUN_MIGRATIONS: $RUN_MIGRATIONS"

if [ "${RUN_MIGRATIONS,,}" = "true" ]; then
    echo "[START(Entry)] Running Alembic migrations..."
    if ! python -m alembic upgrade head; then
      echo "[ERROR] Alembic failed. Resetting migrations..."
      ./reset_alembic.sh
      echo "[RETRY(Entry)] Running Alembic migrations again..."
      python -m alembic upgrade head
    fi
else
    echo "[SKIP(Entry)] Alembic migrations (RUN_MIGRATIONS=${RUN_MIGRATIONS})"
fi

echo "[START(Entry)] Starting FastAPI..."
exec uvicorn main:app --host 0.0.0.0 --port ${CONTAINER_PORT:-8080}
