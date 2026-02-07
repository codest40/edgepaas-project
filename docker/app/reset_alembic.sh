#!/bin/bash
set -euo pipefail

echo "[ALEMBIC] Resetting migrations..."

# Remove Alembic versions folder
rm -rf /app/alembic/versions/*

# Full path to ensure psql is found
/usr/pgsql-15/bin/psql $DATABASE_URL -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public;"

echo "[ALEMBIC] Alembic versions cleared. ✅"
