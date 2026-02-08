#!/bin/bash
set -euo pipefail

echo "[BOOTSTRAP] Initializing environment..."

# ----------------------------
# Normalize booleans
# ----------------------------
USE_SQLITE="${USE_SQLITE:-false}"
BOTH_DB="${BOTH_DB:-false}"
RUN_MIGRATIONS="${RUN_MIGRATIONS:-true}"

USE_SQLITE="${USE_SQLITE,,}"
BOTH_DB="${BOTH_DB,,}"
RUN_MIGRATIONS="${RUN_MIGRATIONS,,}"

# ----------------------------
# Defaults
# ----------------------------
DATABASE_URL_SQLITE="${DATABASE_URL_SQLITE:-sqlite:////opt/edgepaas/fallback.db}"

# ----------------------------
# Validate booleans
# ----------------------------
for var_name in USE_SQLITE BOTH_DB RUN_MIGRATIONS; do
    val="${!var_name}"

    # Strip spaces, quotes, then lowercase it
    val="$(echo "$val" | tr -d '[:space:]\"' | tr '[:upper:]' '[:lower:]')"

    if [[ "$val" != "true" && "$val" != "false" ]]; then
        echo "❌ Invalid boolean: $var_name=$val"
        exit 1
    fi

    export "$var_name"="$val"             # export
done

# ----------------------------
# Resolve final DB mode
# ----------------------------
if [[ "$USE_SQLITE" == "true" ]]; then
    export FINAL_DB_MODE="sqlite_only"
    export DATABASE_URL="$DATABASE_URL_SQLITE"
    export RUN_MIGRATIONS="false"
    echo "[BOOTSTRAP] SQLite-only mode enabled"

elif [[ "$BOTH_DB" == "true" ]]; then
    export FINAL_DB_MODE="try_postgres"
    echo "[BOOTSTRAP] BOTH_DB mode enabled: Try Postgres first, fallback to SQLite"

else
    export FINAL_DB_MODE="postgres_only"
    if [[ -z "${DATABASE_URL:-}" ]]; then
        echo "❌ DATABASE_URL must be set for Postgres mode"
        exit 1
    fi
    echo "[BOOTSTRAP] Postgres-only mode enabled"
fi

# ----------------------------
# Final report
# ----------------------------
echo "[BOOTSTRAP] Environment configuration:"
echo "  FINAL_DB_MODE=$FINAL_DB_MODE"
echo "  USE_SQLITE=$USE_SQLITE"
echo "  BOTH_DB=$BOTH_DB"
echo "  RUN_MIGRATIONS=$RUN_MIGRATIONS"
echo "  DATABASE_URL=$DATABASE_URL"
echo "[BOOTSTRAP] Done. ✅"
