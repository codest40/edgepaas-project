# ============================================================
#  DOCKER /app FOLDER OVERVIEW — EDGEPAAS
# ============================================================

# ------------------------------------------------------------
#  OVERVIEW
# ------------------------------------------------------------
- This document describes the structure and responsibilities of the `/app` directory inside the Docker image.
- The folder contains the FastAPI application, database layer, migrations, SRE tooling, and runtime helpers.
- This is the application-layer contract.

# ------------------------------------------------------------
#  DATABASE MIGRATIONS
# ------------------------------------------------------------

## alembic/
- Purpose: PostgreSQL schema migrations ONLY.

Key Files:
- env.py
  - Configures Alembic runtime environment.
  - Sets `target_metadata` from SQLAlchemy models.
  - Defines offline and online migration execution logic.

- versions/*.py
  - Individual migration scripts.
  - Example: initial schema migration.
  - Defines tables such as:
    - weatherusers
    - preferences

Guarantee:
- PostgreSQL schema evolves deterministically.
- No schema drift in production.

# ------------------------------------------------------------
#  SQLITE BOOTSTRAP
# ------------------------------------------------------------

## create_sqlite_tables.py
- Purpose: Bootstrap SQLite database when fallback mode is active.

Behavior:
- Checks that `DATABASE_URL` starts with `sqlite`.
- Executes `Base.metadata.create_all()`.
- Skips execution if PostgreSQL is in use.

Guarantee:
- SQLite environments can initialize without Alembic.

# ------------------------------------------------------------
#  DATABASE OPERATIONS
# ------------------------------------------------------------

## crud.py
- Purpose: Encapsulates database operations.

Operations:
- create_user
- get_user
- create_preference
- get_preferences_by_user

Uses:
- SQLAlchemy Session
- Pydantic schemas

Guarantee:
- Business logic is separated from route handlers.
- No raw SQL inside API routes.

# ------------------------------------------------------------
#  DATABASE ENGINE & SESSION
# ------------------------------------------------------------

## db.py
- Purpose: Central SQLAlchemy engine and session factory.

Responsibilities:
- Detect database type (Postgres vs SQLite).
- Enable SQLite foreign key enforcement.
- Provide:
  - `SessionLocal`
  - FastAPI dependency `get_db()`

Guarantee:
- Single source of truth for DB connectivity.
- Clean dependency injection.

# ------------------------------------------------------------
#  TIMEZONE UTILITY
# ------------------------------------------------------------

## local_tz.py
- Purpose: Timezone handling utility.

Function:
- `timer()` returns current timestamp.
- Uses 'pytz' timezone if it is available.

# ------------------------------------------------------------
#  FASTAPI ENTRYPOINT
# ------------------------------------------------------------

## main.py
- Purpose: Application entrypoint.

Responsibilities:

HTTP Routes:
- `/` → Home
- `/weather` → Fetch weather via OpenWeather API
- `/preferences` → CRUD for user preferences


Additional Responsibilities:
- Static and template handling
- Dependency injection of DB session
- Integration with SRE routers:
  - sre/health.py
  - sre/system_health.py

Uses:
- crud.py
- models.py
- SRE modules

Guarantee:
- Clear separation between routing, business logic, and infrastructure.

# ------------------------------------------------------------
#  ORM MODELS
# ------------------------------------------------------------

## models.py
- Purpose: SQLAlchemy ORM models.

Tables:
- WeatherUser
- Preference

Relationships:
- `WeatherUser.preferences`
- `Preference.user`
- Uses `back_populates` for bidirectional mapping.

Guarantee:
- Schema definition isolated from application logic.

# ------------------------------------------------------------
#  MIGRATION RESET TOOL
# ------------------------------------------------------------

## reset_alembic.py
- Purpose: Force-reset PostgreSQL schema.

Behavior:
- Drops and recreates `public` schema.
- Clears `alembic/versions` directory.
- Prevents execution on SQLite.

Warning:
- PostgreSQL ONLY.
- Intended for controlled environments.

# ------------------------------------------------------------
#  REQUEST / RESPONSE SCHEMAS
# ------------------------------------------------------------

## schemas.py
- Purpose: Pydantic models for validation.

Models:
- UserCreate
- UserOut
- PreferenceCreate
- PreferenceOut

Guarantee:
- Strict request validation.
- Clear API contracts.

# ------------------------------------------------------------
#  SRE LAYER
# ------------------------------------------------------------

## sre/
- Purpose: Application-level observability, health, and alerting.

Key Modules:

logger.py
- Centralized logging.
- File + console output.
- Log rotation enabled.

health.py
- `/health/live`
- `/health/ready`

system_health.py
- CPU, memory, disk checks.
- Triggers alerts on threshold breaches.

send_alert.py
- Sends alerts via webhook or email.

verify_startup.py
- Validates DB connectivity.
- Verifies Alembic migration state.

Guarantee:
- Application health verified before accepting traffic.
- Operational visibility built-in.

# ------------------------------------------------------------
#  DATABASE CONNECTIVITY TEST
# ------------------------------------------------------------

## test.py
- Purpose: Validate PostgreSQL SSL connectivity.

Uses:
- psycopg2
- Reads `DATABASE_URL`

# ------------------------------------------------------------
#  DATABASE WAIT LOGIC
# ------------------------------------------------------------

## wait_for_db_core.py
- Purpose: Core retry logic for PostgreSQL availability.

Function:
- `wait_for_database()`
- Retries connection.
- Raises error after max retries.

Guarantee:
- Prevents application boot before DB readiness.

## wait_for_db.py
- Purpose: Database selection and fallback engine.

Responsibilities:
- Choose between PostgreSQL and SQLite.
- Export `/tmp/db_env.sh` with:
  - DATABASE_URL
  - RUN_MIGRATIONS
  - FINAL_DB_MODE

Supported Modes:
- sqlite_only
- postgres_only
- try_postgres

Additional Behavior:
- Enforces SSL for PostgreSQL.
- Centralizes DB decision logic.

Guarantee:
- Deterministic database behavior across environments.


# ------------------------------------------------------------
#  ARCHITECTURAL PATTERNS
# ------------------------------------------------------------

Clear Separation of Concerns:
- db.py → Engine and session management
- models.py → Schema definitions only
- create_sqlite_tables.py → SQLite bootstrap only
- alembic/ → PostgreSQL migrations only
- crud.py → Data access layer
- main.py → Routing and application logic
- sre/ → Observability and operational safety

Operational Safety:
- SRE layer verifies health before traffic.
- wait_for_db.py centralizes fallback logic.
- No silent database switching.

System Characteristics:
- Environment-aware behavior
- Deterministic startup
- Explicit failure paths
- Built-in health monitoring
- Integrated alerting support
