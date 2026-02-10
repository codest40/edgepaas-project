```text
EdgePaaS — Docker

This directory contains everything required to run the EdgePaaS application inside Docker containers.

The Docker layer is responsible for runtime orchestration and safety, not infrastructure provisioning or business logic. It provides a predictable, environment-agnostic execution unit that works consistently across local development, staging, and production.

What Docker Is Responsible For

Docker handles:

Packaging the application and all dependencies

Normalizing runtime behavior across environments

Handling startup sequencing and database readiness

Bootstrapping schemas when required

Providing a predictable, immutable unit for blue/green deployments

This layer is intentionally self-contained and environment-agnostic.

In short:

Terraform builds the world → Ansible prepares the host → Docker runs the app

What This Layer Solves

The Docker layer ensures that:

The same container runs identically in local, staging, and production

Database availability (PostgreSQL vs SQLite) is detected dynamically at runtime

Startup logic is deterministic and observable

Infrastructure concerns never leak into application logic

Directory Structure

docker/
├─ app/                     # FastAPI application, ORM models, SRE logic
├─ docs/                    # Runtime documentation & container architecture
├─ Dockerfile               # Container image definition
├─ README.md                # Docker runtime documentation
├─ bootstrap_env.sh         # Normalizes and validates environment variables
├─ entrypoint.sh            # Main container startup and control flow
├─ wait_for_db.py           # Runtime DB selection & availability checker
└─ create_sqlite_tables.py  # SQLite schema bootstrapper

Repository Snapshot

docker/
├── Dockerfile
├── README.md
├── app/
│   ├── alembic/
│   ├── alembic.ini
│   ├── bootstrap_env.sh
│   ├── create_sqlite_tables.py
│   ├── crud.py
│   ├── db.py
│   ├── entrypoint.sh
│   ├── local_tz.py
│   ├── main.py
│   ├── models.py
│   ├── reset_alembic.py
│   ├── reset_alembic.sh
│   ├── schemas.py
│   ├── test.py
│   ├── wait_for_db.py
│   ├── wait_for_db_core.py
│   ├── websock.py
│   └── sre/
└── docs/
    ├── files.md
    └── runtime.md

Component Breakdown

app/

Contains the application runtime itself:

FastAPI service

SQLAlchemy ORM models

CRUD logic and schemas

WebSocket manager

Health checks and SRE-related logic

Business logic is fully isolated from infrastructure concerns.
The application assumes nothing about where it is running — cloud, local, CI, or edge.

bootstrap_env.sh

Responsible for environment normalization at container startup.

Typical responsibilities:

Validate required environment variables

Apply safe defaults where allowed

Prevent undefined or unsafe runtime states

entrypoint.sh

The main runtime orchestrator for the container.

Responsibilities include:

Sourcing normalized environment variables

Waiting for database availability

Triggering SQLite bootstrap when required

Starting the FastAPI server

This script controls execution flow but does not contain business logic.

wait_for_db.py

Runtime database decision engine.

Responsibilities:

Detect PostgreSQL availability

Fall back safely to SQLite when required

Retry PostgreSQL connections when configured

Export final database configuration to /tmp/db_env.sh

create_sqlite_tables.py

SQLite schema bootstrapper.

Creates all tables using SQLAlchemy metadata

Runs only when SQLite fallback mode is active

Safe and idempotent for repeated execution

docs/

Contains runtime and architectural documentation related to container execution.

runtime.md — detailed container startup and runtime behavior

files.md — supporting documentation

Design Principle

Docker knows nothing about Terraform or Ansible.

It assumes:

The host is ready

The container is immutable

Runtime decisions must be safe, observable, and deterministic
```
