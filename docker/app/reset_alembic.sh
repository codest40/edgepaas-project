#!/bin/bash
set -euo pipefail

echo "[ALEMBIC] Resetting migrations..."

# Remove Alembic versions folder (dangerous in prod!)
rm -rf /app/alembic/versions/*

# Reset the DB (Test)
 psql $DATABASE_URL -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public;"

echo "[ALEMBIC] Alembic versions cleared."
