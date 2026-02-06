#!/usr/bin/env python3
"""
Wait for database before starting app.
Tries: Main DB with SSL → Main DB without SSL → TEST_DB (independent retries)
"""

import os
from urllib.parse import urlparse, parse_qs, urlencode, urlunparse
from dotenv import load_dotenv
from wait_for_db_core import wait_for_database

# Load environment
load_dotenv("/opt/edgepaas/.env.test")

DATABASE_URL = os.getenv("DATABASE_URL")
TEST_DB = os.getenv("DATABASE_URL_TEST")
RETRY_INTERVAL = int(os.getenv("RETRY_INTERVAL", 3))
MAX_RETRIES = int(os.getenv("MAX_RETRIES", 5))
TEST_DB_RETRIES = int(os.getenv("TEST_DB_RETRIES", 6))  # independent retry count for TEST_DB

def add_sslmode(url: str) -> str:
    try:
        if not url:
            return url
        parsed = urlparse(url)
        query = parse_qs(parsed.query)
        if "sslmode" not in query:
            query["sslmode"] = ["require"]
        new_query = urlencode(query, doseq=True)
        return urlunparse(parsed._replace(query=new_query))
    except:
        return url

def remove_sslmode(url: str) -> str:
    try:
        if not url:
            return url
        parsed = urlparse(url)
        query = parse_qs(parsed.query)
        query.pop("sslmode", None)
        new_query = urlencode(query, doseq=True)
        return urlunparse(parsed._replace(query=new_query))
    except:
        return url

print("[START] Waiting for database...")

# --- Stage 1: Main DB with SSL ---
try:
    wait_for_database(add_sslmode(DATABASE_URL), MAX_RETRIES, RETRY_INTERVAL)
    final_db_url = add_sslmode(DATABASE_URL)
except RuntimeError:
    print("[WARN] Main DB with SSL failed, retrying without SSL")
    # --- Stage 2: Main DB without SSL ---
    try:
        wait_for_database(remove_sslmode(DATABASE_URL), MAX_RETRIES, RETRY_INTERVAL)
        final_db_url = remove_sslmode(DATABASE_URL)
    except RuntimeError:
        print("[WARN] Main DB without SSL failed, switching to TEST_DB")
        # --- Stage 3: TEST_DB with independent retries ---
        wait_for_database(TEST_DB, TEST_DB_RETRIES, RETRY_INTERVAL)
        final_db_url = TEST_DB

print(f"[DONE] Database ready: {final_db_url}")
#DATABASE_URL = final_db_url
os.environ["DATABASE_URL"] = final_db_url

