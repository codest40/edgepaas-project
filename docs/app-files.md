```text
Docker /app folder overview

1. alembic/

Purpose: PostgreSQL schema migrations only

Key files:

env.py → configures Alembic runtime environment, sets target_metadata from SQLAlchemy models, defines offline/online migration functions

versions/*.py → individual migration scripts (963eb932bdd4_initial_weather_schema.py) defining tables: weatherusers and preferences


2. create_sqlite_tables.py

Purpose: Bootstrap SQLite database if fallback mode is active

Behavior:

Checks DATABASE_URL starts with sqlite

Creates all tables via Base.metadata.create_all()

Skips if using PostgreSQL


3. crud.py

Purpose: Encapsulates database operations

Operations:

create_user, get_user

create_preference, get_preferences_by_user

Uses: SQLAlchemy Session, Pydantic schemas


4. db.py

Purpose: Central SQLAlchemy engine and session factory

Responsibilities:

Detects DB type (Postgres vs SQLite)

Enables SQLite foreign keys

Provides SessionLocal and FastAPI dependency get_db()


5. local_tz.py

Purpose: Timezone handling utility

Function: timer() returns current timestamp, uses Africa/Lagos if pytz available


6. main.py

Purpose: FastAPI entrypoint

Responsibilities:

HTTP routes:

/ → Home

/weather → fetch weather via OpenWeather API

/preferences → CRUD for user preferences

WebSocket /ws/alerts → real-time notifications

Static and template handling

Dependency injection of DB session

Notes: Uses crud.py, models.py, SRE routers (sre/health.py, sre/system_health.py)


7. models.py

Purpose: SQLAlchemy ORM models

Tables:

WeatherUser

Preference

Relationships: WeatherUser.preferences back_populates Preference.user


8. reset_alembic.py

Purpose: Force-reset Postgres schema

Behavior:

Drops and recreates public schema

Clears alembic/versions directory

PostgreSQL-only, prevents running on SQLite


9. schemas.py

Purpose: Pydantic models for request/response validation

Models:

UserCreate, UserOut

PreferenceCreate, PreferenceOut


10. sre/

Purpose: Application-level SRE / health / alerting

Key modules:

logger.py → centralized logging (file + console, rotation)

health.py → /health/live and /health/ready endpoints

system_health.py → system metrics check (CPU, memory, disk), triggers alerts

send_alert.py → sends alerts via webhook or email

verify_startup.py → checks DB connectivity and Alembic migrations


11. test.py

Purpose: Test Postgres SSL connectivity

Uses: psycopg2, validates DATABASE_URL


12. wait_for_db_core.py

Purpose: Core DB wait/retry logic for Postgres

Function: wait_for_database(), retries connection, raises after max retries


13. wait_for_db.py

Purpose: Database decision engine

Responsibilities:

Chooses between Postgres and SQLite fallback

Exports /tmp/db_env.sh with:

DATABASE_URL

RUN_MIGRATIONS

FINAL_DB_MODE

Handles modes:

sqlite_only, postgres_only, try_postgres

Ensures SSL for Postgres


14. websock.py

Purpose: WebSocket connection manager

Class: ConnectionManager

Methods: connect, disconnect, send_personal_message, broadcast

Global instance: manager


✅ Key Patterns

Clear separation:

db.py → engine/session (no migrations)

models.py → schema only

create_sqlite_tables.py → SQLite bootstrap

alembic/ → Postgres migrations

SRE layer ensures app is healthy before accepting traffic

wait_for_db.py centralizes DB selection and fallback logic

FastAPI handles business logic + WebSocket communication

Alerts via sre/send_alert.py integrate with monitoring/Slack/email
```
