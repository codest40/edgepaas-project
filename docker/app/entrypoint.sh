#!/bin/bash
set -e

echo "[START] Waiting for DB..."
python wait_for_db.py

# Run Alembic only if RUN_MIGRATIONS is set to true
echo "Detected Env RUN_MIGRATIONS: $RUN_MIGRATIONS"

if [ "${RUN_MIGRATIONS,,}" = "true" ]; then
    echo "[START] Running Alembic migrations..."
    python -m alembic upgrade head
else
    echo "[SKIP] Alembic migrations (RUN_MIGRATIONS=${RUN_MIGRATIONS})"
fi

echo "[START] Starting FastAPI..."
exec uvicorn main:app --host 0.0.0.0 --port 8080
