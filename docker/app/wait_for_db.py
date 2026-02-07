#!/usr/bin/env python3
"""
Wait for database before starting app.

Order:
1) Render PostgreSQL (SSL required)
2) SQLite fallback (boot only)
"""

import os
from urllib.parse import urlparse
from dotenv import load_dotenv
from wait_for_db_core import wait_for_database

# Load env
load_dotenv("/opt/edgepaas/.env.test")

DATABASE_URL = os.getenv("DATABASE_URL")
SQLITE_FALLBACK = os.getenv("SQLITE_FALLBACK_URL", "sqlite:///./fallback.db")

RETRY_INTERVAL = int(os.getenv("RETRY_INTERVAL", 3))
MAX_RETRIES = int(os.getenv("MAX_RETRIES", 6))

def is_postgres(url: str) -> bool:
    return url and url.startswith("postgresql://")

def is_sqlite(url: str) -> bool:
    return url and url.startswith("sqlite")

def ensure_ssl(url: str) -> str:
    if "sslmode=" in url:
        return url
    return url + ("&" if "?" in url else "?") + "sslmode=require"

print("[START] Waiting for database...")

# ----------------------------
# Stage 1: Render PostgreSQL (SSL ONLY)
# ----------------------------

if not DATABASE_URL:
    raise RuntimeError("DATABASE_URL is not set")

if not is_postgres(DATABASE_URL):
    raise RuntimeError("Primary DATABASE_URL must be PostgreSQL")

postgres_url = ensure_ssl(DATABASE_URL)

try:
    wait_for_database(postgres_url, MAX_RETRIES, RETRY_INTERVAL)
    final_db_url = postgres_url
    print("[DB] Using Render PostgreSQL (SSL enforced)")
except RuntimeError as e:
    print(f"[WARN] Render DB unreachable: {e}")
    print("[WARN] Falling back to SQLite (BOOTSTRAP MODE)")

    if not is_sqlite(SQLITE_FALLBACK):
        raise RuntimeError("SQLite fallback URL is invalid")

    final_db_url = SQLITE_FALLBACK
    print("[DB] Using SQLite fallback")

# Export final DB
os.environ["DATABASE_URL"] = final_db_url
print(f"[DONE] Database ready: {final_db_url}")
