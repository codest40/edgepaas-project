# EdgePaaS App — Runtime Architecture (Docker)

This document describes the **runtime architecture** of the EdgePaaS application when running inside Docker.  
It explains the **purpose, responsibility, and boundaries** of every active runtime file involved in startup **and production safety**.

---

## System Goals

The runtime system is designed to provide:

- **PostgreSQL** as the primary database
- **SQLite** as an automatic fallback so the app must start
- **Zero-crash startup** with sane defaults
- **Clean separation of concerns**

### Environment → DB Decision → Schema → Application → SRE Safety Net


---

## Runtime Components

---

## `entrypoint.sh` — Runtime Orchestrator

**Role**  
The single source of truth for application startup inside the container.

### Responsibilities
- Bootstrap environment variables
- Trigger database availability checks
- Apply SQLite fallback logic
- Ensure database files and schema exist
- Control migration execution
- Start the FastAPI application

### Key Behaviors
- Sources `bootstrap_env.sh`
- Executes `wait_for_db.py` to determine the final database
- Creates `/tmp/edgepaas/fallback.db` inside the container
- Runs `create_sqlite_tables.py` only when SQLite is active
- Automatically disables Alembic when SQLite is used
- Starts Uvicorn with the resolved configuration

### What It Does NOT Do
- ❌ Create SQLAlchemy engines
- ❌ Define database schema
- ❌ Contain database logic

> `entrypoint.sh` coordinates startup — it never decides schema or database internals.

---

## `bootstrap_env.sh` — Environment Normalizer

**Role**  
Sanitize and normalize all environment variables **before any Python code runs**.

### Responsibilities
- Provide defaults for:
- `USE_SQLITE`
- `BOTH_DB`
- `RUN_MIGRATIONS`
- Normalize boolean values (`true` / `false`)
- Ensure predictable behavior across Docker and CI/CD

### Why It Matters
- Prevents crashes caused by malformed environment variables
- Keeps Python code free of env-validation logic
- Guarantees all env vars are safe to trust after execution

---

## `wait_for_db.py` — Database Decision Engine

**Role**  
Determine which database should be used at runtime.

### Responsibilities
- Attempt to connect to PostgreSQL
- Retry with backoff
- Detect SSL or network failures
- Fall back to SQLite when PostgreSQL is unavailable
- Write the final database decision to `/tmp/db_env.sh`

### Outputs
- `DATABASE_URL`
- `RUN_MIGRATIONS`
- `FINAL_DB_MODE`

### Critical Design Rule
This script **decides the database** — it does **not**:
- ❌ Create engines
- ❌ Create tables
- ❌ Perform migrations

---

##  `/tmp/db_env.sh` — Final Runtime Contract

**Role**  
The canonical and final database configuration for the container.

- **Written by:** `wait_for_db.py`
- **Consumed by:** `entrypoint.sh`

### Contents
- `DATABASE_URL`
- `RUN_MIGRATIONS`
- `FINAL_DB_MODE`

> Anything defined here **overrides all previous assumptions**.

---

## `db.py` — SQLAlchemy Engine & Session Factory

**Role**  
Create the database engine and session factory using the final `DATABASE_URL`.

### Responsibilities
- Read `DATABASE_URL` from the environment
- Detect SQLite vs PostgreSQL
- Configure SQLAlchemy engine correctly
- Enable SQLite foreign keys
- Provide:
- `SessionLocal`
- `get_db()`

### Explicit Non-Responsibilities
- ❌ Create tables
- ❌ Run migrations
- ❌ Decide database type

### Guarantees
- No side effects on import
- Safe reuse across FastAPI, scripts, and background workers

---

##  `models.py` — Schema Definition Layer

**Role**  
Define database tables and relationships.

### Responsibilities
- SQLAlchemy ORM models
- Table names
- Relationships
- Constraints

### Important Notes
- Imports `Base` from `db.py`
- Does **not** know or care which database is used
- Models are **database-agnostic**

---

##  `create_sqlite_tables.py` — SQLite Bootstrapper

**Role**  
Create database tables **only when SQLite is active**.

### Responsibilities
- Detect SQLite via `DATABASE_URL`
- Load ORM models
- Create tables using `Base.metadata.create_all()`

### Design Guarantees
- Idempotent
- Safe to run multiple times
- Never touches PostgreSQL

> This script intentionally replaces Alembic for SQLite.

---

##  `alembic/` + `alembic.ini` — PostgreSQL Migrations

**Role**  
Schema evolution for PostgreSQL only.

### Used When
- `RUN_MIGRATIONS=true`
- Database is PostgreSQL

### Explicitly Skipped When
- SQLite is active
- Fallback mode is triggered

---

##  `reset_alembic.py` / `reset_alembic.sh` — Migration Recovery Tools

**Role**  
Emergency recovery tooling for failed PostgreSQL migrations.

### Used Only When
- Alembic upgrade fails
- PostgreSQL is active

---

##  `sre/` — Production Safety Net

This folder is the **SRE layer** of the application.

It answers three critical questions:

1. **Is the app alive?** (process running)
2. **Is the app ready?** (DB reachable + schema correct)
3. **If something breaks, who gets notified?**

> Think **Kubernetes-style health checks + startup verification + alerting**, implemented at the **application level**.

---

## `sre/logger.py` — Central Logging Primitive

### Purpose
Provide a **single logger instance** for the entire application.

### Logging Targets
- Rotated log file
- Console (`stdout`)
- Works locally and in cloud/VM environments

### What It Does
- Determines log path:
- Cloud (`AWS=true`) → `/opt/edgepaas/app/logger.log`
- Local → `~/edgepaas/logs/logger.log`
- Sets log level from `LOG_LEVEL`
- Uses `RotatingFileHandler` (5 MB × 5 files)
- Prevents duplicate handlers

### Why This Matters
- Every SRE action must be traceable
- Logs are the **first incident responder**

---

## `sre/health.py` — HTTP Health Probes (FastAPI)

This file exposes **health endpoints only** — no business logic.

---

### `/health/live` — Liveness Probe

**Question Answered**
Is the process running?

**Behavior**
- Always returns `200 OK`
- Does **not** check DB, migrations, or external systems

**Why**
- Used by Docker / Kubernetes / Load Balancers
- Determines whether the container should be restarted

---

### `/health/ready` — Readiness Probe

**Question Answered**
Is the app safe to receive traffic?


**Checks**
- `check_db()` → database connectivity
- `check_migrations()` → schema correctness

**Returns**
- `200 OK` → app may receive traffic
- `503` → remove app from load balancer

**Why**
- Prevents traffic reaching an app that:
  - Cannot reach its DB
  - Has mismatched schema

This endpoint is only as good as `verify_startup.py`

---

## `sre/verify_startup.py` — Hard Gate Before Trust

This is the **brain of SRE**.

---

### `check_db()`

**Purpose**
Prove the database is reachable and responding.

**How**
- Builds SQLAlchemy engine using `DATABASE_URL`
- Executes `SELECT 1`

**Failure Means**
- Wrong database selected
- Database is down
- Bad credentials
- SSL / driver issues

---

### `check_migrations()`

**Purpose**
Ensure database schema matches application schema.

**How**
- Reads Alembic configuration
- Compares:
  - Current DB revision
  - Latest migration head

**Failure Means**
- Application code and DB schema are out of sync  
  (this prevents silent data corruption)

---

### `run_startup_checks()`

- Runs all critical checks
- Reusable by:
  - `/health/ready`
  - Entrypoint scripts
  - CI validation

---

### `main()`

**Purpose**
CLI-style startup verification.

**Behavior**
- On failure:
  - Logs error
  - Sends alert
  - Exits with code `1`

> This is SRE gold.

Use before:
- Starting Uvicorn
- Enabling traffic
- Promoting a release

---

## `sre/send_alert.py` — Incident Notification Layer

### Purpose
Notify humans when automation detects failure.

### Alert Order
1. Webhook (Slack, Discord, Teams, etc.)
2. Email fallback
3. Log-only if nothing is configured

### `send_alert(message)`
- Logs alert at `ERROR` level
- Attempts webhook delivery
- Falls back to email

### Why
- Machines detect problems
- Humans fix them

---

## End-to-End Startup & Safety Flow


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
verify_startup.py (SRE hard gate)
↓
FastAPI starts
↓
/health/live & /health/ready active


---

##  Architectural Guarantees

- ✔ No database ambiguity
- ✔ No race conditions
- ✔ SQLite and PostgreSQL never conflict
- ✔ Containers always own their database files
- ✔ App never crashes due to missing DB
- ✔ Traffic never reaches an unhealthy app
- ✔ Failures always leave a trail

