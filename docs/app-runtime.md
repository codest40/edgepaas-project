# ============================================================
#  EDGEPAAS APP — RUNTIME ARCHITECTURE (DOCKER)
# ============================================================

This document describes the runtime architecture of the EdgePaaS application
when running inside Docker.

It defines the purpose, responsibility, and strict boundaries of every
active runtime component involved in startup and production safety.

# ============================================================
#  SYSTEM GOALS
# ============================================================

The runtime system is designed to provide:

- PostgreSQL as the primary database
- SQLite as an automatic fallback so the app MUST start
- Zero-crash startup with sane defaults
- Clean separation of concerns

Flow:

Environment
→ Database Decision
→ Schema Resolution
→ Application Boot
→ SRE Safety Net

# ============================================================
#  RUNTIME COMPONENTS
# ============================================================


# ------------------------------------------------------------
#  entrypoint.sh — Runtime Orchestrator
# ------------------------------------------------------------

Role:
- Single source of truth for container startup.

Responsibilities:
- Bootstrap environment variables
- Trigger database availability checks
- Apply SQLite fallback logic
- Ensure database files and schema exist
- Control migration execution
- Start the FastAPI application

Key Behaviors:
- Sources bootstrap_env.sh
- Executes wait_for_db.py to determine final database
- Creates /tmp/edgepaas/fallback.db inside container
- Runs create_sqlite_tables.py when SQLite is active
- Automatically disables Alembic when SQLite is used
- Starts Uvicorn with resolved configuration

Explicit Non-Responsibilities:
- Does NOT create SQLAlchemy engines
- Does NOT define schema
- Does NOT contain database logic

Design Rule:
entrypoint.sh coordinates startup.
It never decides schema or database internals.


# ------------------------------------------------------------
#  bootstrap_env.sh — Environment Normalizer
# ------------------------------------------------------------

Role:
- Sanitize and normalize environment variables BEFORE Python runs.

Responsibilities:
- Provide defaults for:
  - USE_SQLITE
  - BOTH_DB
  - RUN_MIGRATIONS
- Normalize boolean values (true / false)
- Ensure predictable behavior across Docker and CI/CD

Why This Matters:
- Prevents crashes from malformed env variables
- Keeps Python code free of env validation logic
- Guarantees environment variables are safe to trust


# ------------------------------------------------------------
#  wait_for_db.py — Database Decision Engine
# ------------------------------------------------------------

Role:
- Decide which database should be used at runtime.

Responsibilities:
- Attempt PostgreSQL connection
- Retry with backoff
- Detect SSL or network failures
- Fall back to SQLite if PostgreSQL unavailable
- Write final decision to /tmp/db_env.sh

Outputs:
- DATABASE_URL
- RUN_MIGRATIONS
- FINAL_DB_MODE

Critical Rule:
This script decides the database.
It does NOT:
- Create engines
- Create tables
- Perform migrations


# ------------------------------------------------------------
#  /tmp/db_env.sh — Final Runtime Contract
# ------------------------------------------------------------

Role:
- Canonical and final database configuration for container.

Written By:
- wait_for_db.py

Consumed By:
- entrypoint.sh

Contents:
- DATABASE_URL
- RUN_MIGRATIONS
- FINAL_DB_MODE

Rule:
Anything defined here overrides all previous assumptions.


# ------------------------------------------------------------
#  db.py — SQLAlchemy Engine & Session Factory
# ------------------------------------------------------------

Role:
- Create engine and session factory using final DATABASE_URL.

Responsibilities:
- Read DATABASE_URL from environment
- Detect SQLite vs PostgreSQL
- Configure SQLAlchemy engine properly
- Enable SQLite foreign keys
- Provide:
  - SessionLocal
  - get_db()

Explicit Non-Responsibilities:
- Does NOT create tables
- Does NOT run migrations
- Does NOT decide database type

Guarantees:
- No side effects on import
- Safe reuse across FastAPI, scripts, background workers


# ------------------------------------------------------------
#  models.py — Schema Definition Layer
# ------------------------------------------------------------

Role:
- Define database tables and relationships.

Responsibilities:
- SQLAlchemy ORM models
- Table names
- Relationships
- Constraints

Important Notes:
- Imports Base from db.py
- Database-agnostic
- Does not know which engine is active


# ------------------------------------------------------------
#  create_sqlite_tables.py — SQLite Bootstrapper
# ------------------------------------------------------------

Role:
- Create tables ONLY when SQLite is active.

Responsibilities:
- Detect SQLite via DATABASE_URL
- Load ORM models
- Execute Base.metadata.create_all()

Guarantees:
- Idempotent
- Safe to run multiple times
- Never touches PostgreSQL

Design Intent:
Replaces Alembic when SQLite is active.


# ------------------------------------------------------------
#  alembic/ + alembic.ini — PostgreSQL Migrations
# ------------------------------------------------------------

Role:
- Schema evolution for PostgreSQL ONLY.

Used When:
- RUN_MIGRATIONS=true
- Database is PostgreSQL

Skipped When:
- SQLite is active
- Fallback mode triggered


# ------------------------------------------------------------
#  reset_alembic.py / reset_alembic.sh — Recovery Tools
# ------------------------------------------------------------

Role:
- Emergency recovery for failed PostgreSQL migrations.

Used Only When:
- Alembic upgrade fails
- PostgreSQL is active


# ------------------------------------------------------------
#  sre/ — Production Safety Net
# ------------------------------------------------------------

The SRE layer answers three critical questions:

- Is the app alive?
- Is the app ready?
- If something breaks, who gets notified?

This is like Kubernetes-style health + startup verification + alerting,
implemented at application level.


# ------------------------------------------------------------
#  sre/logger.py — Central Logging Primitive
# ------------------------------------------------------------

Purpose:
- Provide a single logger instance.

Logging Targets:
- Rotated log file
- Console (stdout)

Behavior:
- Determines log path:
  - Cloud (AWS=true) → /opt/edgepaas/app/logger.log
  - Local → ~/edgepaas/logs/logger.log
- Sets log level from LOG_LEVEL
- Uses RotatingFileHandler (5 MB × 5 files)
- Prevents duplicate handlers

Why It Matters:
Logs are the first incident responder.


# ------------------------------------------------------------
#  sre/health.py — HTTP Health Probes
# ------------------------------------------------------------

Exposes health endpoints only.
Contains NO business logic.


/health/live — Liveness Probe

Question:
Is the process running?

Behavior:
- Always returns 200 OK
- Does NOT check DB or external systems

Used By:
- Docker
- Kubernetes
- Load balancers


/health/ready — Readiness Probe

Question:
Is the app safe to receive traffic?

Checks:
- check_db()
- check_migrations()

Returns:
- 200 OK → safe
- 503 → remove from load balancer

Prevents:
- Traffic reaching DB-broken app
- Schema mismatch corruption


# ------------------------------------------------------------
#  sre/verify_startup.py — Hard Trust Gate
# ------------------------------------------------------------

This is the core SRE validator.


check_db()

Purpose:
- Prove DB is reachable and responding.

Method:
- Build engine using DATABASE_URL
- Execute SELECT 1

Failure Means:
- Wrong DB
- DB down
- Bad credentials
- SSL/driver issue


check_migrations()

Purpose:
- Ensure DB schema matches application schema.

Method:
- Read Alembic config
- Compare current revision vs head

Failure Means:
- Code and schema out of sync


run_startup_checks()

- Runs all critical checks
- Reusable by:
  - /health/ready
  - Entrypoint scripts
  - CI validation


main()

Behavior:
- On failure:
  - Log error
  - Send alert
  - Exit with code 1

Use Before:
- Starting Uvicorn
- Enabling traffic
- Promoting release


# ------------------------------------------------------------
#  sre/send_alert.py — Incident Notification Layer
# ------------------------------------------------------------

Purpose:
- Notify humans when automation detects failure.

Alert Order:
- Webhook (Slack, Teams, Discord, etc.)
- Email fallback
- Log-only if nothing configured

send_alert(message):
- Log at ERROR level
- Attempt webhook
- Fallback to email

Principle:
Machines detect.
Humans fix.


# ============================================================
#  END-TO-END STARTUP & SAFETY FLOW
# ============================================================
```
bootstrap_env.sh
↓
wait_for_db.py → writes /tmp/db_env.sh
↓
entrypoint.sh (sources final env)
↓
SQLite file + tables (if needed)
↓
db.py creates engine
↓
verify_startup.py (hard SRE gate)
↓
FastAPI starts
↓
/health/live and /health/ready active

```
# ============================================================
#  ARCHITECTURAL GUARANTEES
# ============================================================

- No database ambiguity
- No race conditions
- SQLite and PostgreSQL never conflict
- Containers own their database files
- App never crashes due to missing DB
- Traffic never reaches unhealthy app
- Failures always leave a trace
