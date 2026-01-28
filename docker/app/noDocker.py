# noDocker.py
"""
Run the FastAPI app locally without Docker.

- Reuses wait_for_db.py to wait for DB readiness.
- Applies Alembic migrations.
- Starts FastAPI with hot reload.
"""

import subprocess
import sys

# --- Step 1: Wait for DB ---
print("[NO_DOCKER] Waiting for database...")
subprocess.run([sys.executable, "wait_for_db.py"], check=True)

# --- Step 2: Apply Alembic migrations ---
print("[NO_DOCKER] Applying migrations with Alembic...")
subprocess.run([sys.executable, "-m", "alembic", "upgrade", "head"], check=True)

# --- Step 3: Start FastAPI app ---
print("[NO_DOCKER] Starting FastAPI app with hot reload...")
subprocess.run([
    "uvicorn",
    "main:app",
    "--reload",
    "--host", "127.0.0.1",
    "--port", "8000"
])
