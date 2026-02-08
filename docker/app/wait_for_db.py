#!/usr/bin/env python3
"""
Wait for database before starting app.
Order:
1) Render PostgreSQL (SSL required)
2) SQLite fallback (boot only)
"""

import os
import time
from urllib.parse import urlparse, parse_qs, urlencode, urlunparse
from dotenv import load_dotenv
from wait_for_db_core import wait_for_database
from local_tz import timer

# Load env
load_dotenv("/opt/edgepaas/.env.test")

DATABASE_URL = os.getenv("DATABASE_URL")
SQLITE_FALLBACK = os.getenv("DATABASE_URL_SQLITE", "sqlite:////opt/edgepaas/fallback.db")

RETRY_INTERVAL = int(os.getenv("RETRY_INTERVAL", 3))
MAX_RETRIES = int(os.getenv("MAX_RETRIES", 6))

def is_postgres(url: str) -> bool:
    return url and url.startswith("postgresql://")

def is_sqlite(url: str) -> bool:
    return url and url.startswith("sqlite")

def add_sslmode(url: str) -> str:
    """Add sslmode=require to PostgreSQL URL if missing"""
    if not url or not is_postgres(url):
        return url
    parsed = urlparse(url)
    query = parse_qs(parsed.query)
    query["sslmode"] = ["require"]
    new_query = urlencode(query, doseq=True)
    return urlunparse(parsed._replace(query=new_query))

print(f"[{timer()}] [START] Waiting for database...")

# ----------------------------
# Stage 1: Render PostgreSQL (SSL ONLY)
# ----------------------------
if not DATABASE_URL:
    raise RuntimeError("DATABASE_URL is not set")

postgres_url = add_sslmode(DATABASE_URL)

try:
    wait_for_database(postgres_url, MAX_RETRIES, RETRY_INTERVAL)
    final_db_url = postgres_url
    print(f"[{timer()}] [DB] Using Render PostgreSQL (SSL enforced)")
except RuntimeError as e:
    print(f"[{timer()}] [WARN] Render DB unreachable: {e}")
    print(f"[{timer()}] [WARN] Falling back to SQLite (BOOTSTRAP MODE)")

    if not is_sqlite(SQLITE_FALLBACK):
        raise RuntimeError("SQLite fallback URL is invalid")

    final_db_url = SQLITE_FALLBACK
    print(f"[{timer()}] [DB] Using SQLite fallback: {final_db_url}")

# Export final DB
os.environ["DATABASE_URL"] = final_db_url
print(f"[{timer()}] [DONE] Database ready: {final_db_url}")

# Export For entrypoint.sh
print(f"export DATABASE_URL='{final_db_url}'")
