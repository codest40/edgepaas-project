# wait_for_db.py
"""
Purpose:
    Ensures the database is ready before starting the application.
    This prevents connection errors when the app starts faster than the DB.
Usage:
    CMD python wait_for_db.py && alembic upgrade head && uvicorn main:app ...
"""

import time
from datetime import datetime
import os
import psycopg2
from db import DATABASE_URL as DEFAULT_DATABASE_URL
from urllib.parse import urlparse, parse_qs, urlencode, urlunparse


DATABASE_URL = os.getenv("DATABASE_URL", DEFAULT_DATABASE_URL)
# Only add sslmode=require if not present
parsed = urlparse(DATABASE_URL)
query = parse_qs(parsed.query)

if "sslmode" not in query:
    query["sslmode"] = "require"

# Rebuild URL with updated query string
new_query = urlencode(query, doseq=True)
DATABASE_URL = urlunparse(parsed._replace(query=new_query))

# if "sslmode=" not in DATABASE_URL:
#    DATABASE_URL += "?sslmode=require"

# Config params
RETRY_INTERVAL = 3
MAX_RETRIES = 5
timer = datetime.now().strftime("%H:%M:%S")
print(f"[WAIT_FOR_DB: {timer}] Attempting to connect to database at: {DATABASE_URL}")

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
