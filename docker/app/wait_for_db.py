# wait_for_db.py
"""
Script: wait_for_db.py
Purpose:
    Ensures the database is ready before starting the application.
    This prevents connection errors when the app starts faster than the DB.
Usage:
    CMD python wait_for_db.py && alembic upgrade head && uvicorn main:app ...
"""

import time
import os
import psycopg2
from db import DATABASE_URL as DEFAULT_DATABASE_URL

# Use environment variable first, fallback to db.py default
DATABASE_URL = os.getenv("DATABASE_URL", DEFAULT_DATABASE_URL)

# Config params
RETRY_INTERVAL = 3
MAX_RETRIES = 5

print(f"[WAIT_FOR_DB] Attempting to connect to database at: {DATABASE_URL}")

retry_count = 0
start = time.time()
while retry_count < MAX_RETRIES:
    try:
        conn = psycopg2.connect(DATABASE_URL)
        conn.close()
        end = time.time()
        print(f"[WAIT_FOR_DB] DB ready after {end - start:.2f}s")
        break
    except psycopg2.OperationalError:
        retry_count += 1
        print(f"[WAIT_FOR_DB] Database not ready, retry {retry_count}/{MAX_RETRIES}...")
        time.sleep(RETRY_INTERVAL)
else:
    end = time.time()
    raise RuntimeError(f"[WAIT_FOR_DB] Could not connect to database after {MAX_RETRIES} retries."
        f"(waited {end - start:.2f}s)"
    )
