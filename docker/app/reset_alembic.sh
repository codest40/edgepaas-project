#!/bin/bash
set -euo pipefail

echo "[ALEMBIC] Reset requested..."

# ----------------------------
# Safety checks
# ----------------------------

if [[ -z "${DATABASE_URL:-}" ]]; then
  echo "[FATAL] DATABASE_URL is not set. Aborting."
  exit 1
fi

if [[ "$DATABASE_URL" == sqlite* ]]; then
  echo "[FATAL] Refusing to reset Alembic on SQLite."
  exit 1
fi

if ! [[ "$DATABASE_URL" =~ ^postgresql:// ]]; then
  echo "[FATAL] Unsupported DATABASE_URL scheme."
  exit 1
fi

# ----------------------------
# Preconditions
# ----------------------------

PSQL_BIN="/usr/pgsql-15/bin/psql"

if [[ ! -x "$PSQL_BIN" ]]; then
  echo "[FATAL] psql not found at $PSQL_BIN"
  exit 1
fi

echo "[ALEMBIC] Using PostgreSQL database"
echo "[ALEMBIC] URL host: $(echo "$DATABASE_URL" | sed -E 's|.*@([^:/]+).*|\1|')"

# ----------------------------
# Reset Alembic state
# ----------------------------

echo "[ALEMBIC] Dropping and recreating public schema..."

$PSQL_BIN "$DATABASE_URL" <<'SQL'
DROP SCHEMA IF EXISTS public CASCADE;
CREATE SCHEMA public;
GRANT ALL ON SCHEMA public TO public;
SQL

# ----------------------------
# Cleanup Alembic versions
# ----------------------------

if [[ -d "/app/alembic/versions" ]]; then
  echo "[ALEMBIC] Clearing alembic/versions directory..."
  rm -rf /app/alembic/versions/*
else
  echo "[WARN] /app/alembic/versions not found"
fi

echo "[ALEMBIC] Reset completed successfully ✅"
