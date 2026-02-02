#!/usr/bin/env python3
"""
Wait for database to be ready before starting the app.
Tries DATABASE_URL first, falls back to DATABASE_URL_TEST if needed.
"""

import os
import time
from datetime import datetime
from urllib.parse import urlparse, parse_qs, urlencode, urlunparse
import psycopg2

# Config
DATABASE_URL = os.getenv("DATABASE_URL")
TEST_DB = os.getenv("DATABASE_URL_TEST")
RETRY_INTERVAL = 3
MAX_RETRIES = 5
FALLBACK_RETRY = 4

def add_sslmode(url):
    """Ensure sslmode=require is set"""
    parsed = urlparse(url)
    query = parse_qs(parsed.query)
    if "sslmode" not in query:
        query["sslmode"] = "require"
    new_query = urlencode(query, doseq=True)
    return urlunparse(parsed._replace(query=new_query))

def remove_sslmode(url):
    """Remove sslmode from connection string (for local/test DB)"""
    parsed = urlparse(url)
    query = parse_qs(parsed.query)
    query.pop("sslmode", None)  # remove sslmode if exists
    new_query = urlencode(query, doseq=True)
    return urlunparse(parsed._replace(query=new_query))

DATABASE_URL = add_sslmode(DATABASE_URL)

if TEST_DB:
    TEST_DB = remove_sslmode(TEST_DB)

retry_count = 0
start = time.time()
current_url = DATABASE_URL
using_test_db = False

while retry_count < MAX_RETRIES:
    timer = datetime.now().strftime("%H:%M:%S")
    print(f"[WAIT_FOR_DB: {timer}] Attempt {retry_count+1} connecting to: {current_url}")

    try:
        conn = psycopg2.connect(current_url)
        conn.close()
        end = time.time()
        db_type = "TEST_DB" if using_test_db else "MAIN DB"
        print(f"[WAIT_FOR_DB] {db_type} ready after {end - start:.2f}s")
        break

    except psycopg2.OperationalError as e:
        retry_count += 1
        print(f"[WAIT_FOR_DB] Database not ready (attempt {retry_count}/{MAX_RETRIES})...")

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
