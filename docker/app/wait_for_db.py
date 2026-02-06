#!/usr/bin/env python3
"""
Wait for database to be ready before starting the app.
Tries DATABASE_URL with SSL first, then without SSL if needed,
then falls back to DATABASE_URL_TEST if main DB fails entirely.
Safe SSL handling and local timezone logging.
"""

import os
import time
from datetime import datetime
from urllib.parse import urlparse, parse_qs, urlencode, urlunparse
import psycopg2
from local_tz import timer
from dotenv import load_dotenv

# Load environment
load_dotenv("/opt/edgepaas/.env.test")

# --- Config ---
DATABASE_URL = os.getenv("DATABASE_URL")
TEST_DB = os.getenv("DATABASE_URL_TEST")
RETRY_INTERVAL = int(os.getenv("RETRY_INTERVAL", 3))
MAX_RETRIES = int(os.getenv("MAX_RETRIES", 5))
FALLBACK_RETRY = int(os.getenv("FALLBACK_RETRY", 4))


# --- Utility functions ---
def add_sslmode(url: str) -> str:
    """Ensure sslmode=require is set. Return original URL if error occurs."""
    try:
        if not url:
            return url
        parsed = urlparse(url)
        query = parse_qs(parsed.query)
        if "sslmode" not in query:
            query["sslmode"] = ["require"]
        new_query = urlencode(query, doseq=True)
        return urlunparse(parsed._replace(query=new_query))
    except Exception as e:
        print(f"[WARN] add_sslmode failed ({e}), using original URL")
        return url


def remove_sslmode(url: str) -> str:
    """Remove sslmode from connection string. Return original URL if error."""
    try:
        if not url:
            return url
        parsed = urlparse(url)
        query = parse_qs(parsed.query)
        query.pop("sslmode", None)
        new_query = urlencode(query, doseq=True)
        return urlunparse(parsed._replace(query=new_query))
    except Exception as e:
        print(f"[WARN] remove_sslmode failed ({e}), using original URL")
        return url


# --- Initialize connection attempt ---
retry_count = 0
start = time.time()
using_test_db = False
ssl_tried = True
current_url = add_sslmode(DATABASE_URL)  # Try main DB with SSL first

print(f"[START({timer()})] Waiting for DB...")

while retry_count < MAX_RETRIES:
    now_str = timer()
    print(f"[WAIT_FOR_DB: {now_str}] Attempt {retry_count+1} connecting to: {current_url}")

    try:
        conn = psycopg2.connect(current_url)
        conn.close()
        end = time.time()
        db_type = "TEST_DB" if using_test_db else "MAIN DB"
        print(f"[WAIT_FOR_DB] {db_type} ready after {end - start:.2f}s")
        break

    except psycopg2.OperationalError as e:
        retry_count += 1
        print(f"[WAIT_FOR_DB] Database not ready (attempt {retry_count}/{MAX_RETRIES})... {e}")

        # First fallback: try MAIN DB without SSL
        if ssl_tried and not using_test_db:
            current_url = remove_sslmode(DATABASE_URL)
            ssl_tried = False
            print(f"[WAIT_FOR_DB] SSL failed, retrying MAIN DB without SSL: {current_url}")

        # Second fallback: switch to TEST_DB
        elif retry_count >= FALLBACK_RETRY and TEST_DB and not using_test_db:
            current_url = TEST_DB
            using_test_db = True
            print(f"[WAIT_FOR_DB] MAIN DB unreachable, switching to TEST_DB: {current_url}")

        time.sleep(RETRY_INTERVAL)

else:
    end = time.time()
    raise RuntimeError(
        f"[WAIT_FOR_DB] Could not connect to database after {MAX_RETRIES} retries "
        f"(waited {end - start:.2f}s)"
    )

# Final DB URL to be used by the app
DATABASE_URL = current_url
