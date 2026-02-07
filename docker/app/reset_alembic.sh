#!/bin/bash
set -euo pipefail

export PATH=$PATH:/usr/pgsql-15/bin

echo "[ALEMBIC] Resetting migrations..."

# Remove Alembic versions folder (for Test_DB)
rm -rf /app/alembic/versions/*

# Reset the DB (Test)
 psql $DATABASE_URL -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public;"

echo "[ALEMBIC] Alembic versions cleared. ✅"
