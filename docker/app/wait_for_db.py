#!/usr/bin/env python3
"""
Wait for database to be ready before starting the app.
Tries DATABASE_URL first, falls back to DATABASE_URL_TEST if needed.
Safe SSL handling and local timezone logging.
"""

import os
import time
from datetime import datetime
from urllib.parse import urlparse, parse_qs, urlencode, urlunparse
import psycopg2
from local_tz import timer
from dotenv import load_dotenv
load_dotenv("/opt/edgepaas/.env.test")

# --- Config ---
DATABASE_URL = os.getenv("DATABASE_URL")
TEST_DB = os.getenv("DATABASE_URL_TEST")
RETRY_INTERVAL = int(os.getenv("RETRY_INTERVAL", 3))
MAX_RETRIES = int(os.getenv("MAX_RETRIES", 5))
FALLBACK_RETRY = int(os.getenv("FALLBACK_RETRY", 4))


def add_sslmode(url: str) -> str:
    """Ensure sslmode=require is set. Return original URL if error occurs."""
    try:
        if not url:
            return url
        parsed = urlparse(url)
        query = parse_qs(parsed.query)
        if "sslmode" not in query:
            query["sslmode"] = ["require"]  #list for urlencode(doseq=True)
        new_query = urlencode(query, doseq=True)
        return urlunparse(parsed._replace(query=new_query))
    except Exception as e:
        print(f"[WARN] add_sslmode failed ({e}), using original URL")
        return url


def remove_sslmode(url: str) -> str:
    """Remove sslmode from connection string. Returns original URL if error."""
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


# --- Apply SSL safely ---
DATABASE_URL = add_sslmode(DATABASE_URL)
if TEST_DB:
    TEST_DB = remove_sslmode(TEST_DB)

retry_count = 0
start = time.time()
current_url = DATABASE_URL
using_test_db = False

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

        # Switch to TEST_DB if retry threshold reached
        if retry_count == FALLBACK_RETRY and TEST_DB:
            current_url = TEST_DB
            using_test_db = True
            print(f"[WAIT_FOR_DB] Switching to TEST_DB (no SSL): {current_url}")

        time.sleep(RETRY_INTERVAL)
else:
    end = time.time()
    raise RuntimeError(
        f"[WAIT_FOR_DB] Could not connect to database after {MAX_RETRIES} retries "
        f"(waited {end - start:.2f}s)"
    )

DATABASE_URL = current_url
