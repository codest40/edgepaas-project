#!/usr/bin/env python3
"""
Test if Render Postgres requires SSL.
"""

import os
import psycopg2
from urllib.parse import urlparse, parse_qs, urlencode, urlunparse
from dotenv import load_dotenv

load_dotenv("/opt/edgepaas/.env.test")
load_dotenv(".env")

DATABASE_URL = os.getenv("DATABASE_URL")

def add_sslmode(url: str) -> str:
    parsed = urlparse(url)
    query = parse_qs(parsed.query)
    query["sslmode"] = ["require"]
    return urlunparse(parsed._replace(query=urlencode(query, doseq=True)))

def remove_sslmode(url: str) -> str:
    parsed = urlparse(url)
    query = parse_qs(parsed.query)
    query.pop("sslmode", None)
    return urlunparse(parsed._replace(query=urlencode(query, doseq=True)))

def test_connection(url, label):
    try:
        conn = psycopg2.connect(url)
        conn.close()
        print(f"[SUCCESS] {label} connected!")
    except Exception as e:
        print(f"[FAIL] {label} failed: {e}")

print("Testing Render Postgres connection:")

# Try with SSL
test_connection(add_sslmode(DATABASE_URL), "Main DB with SSL")

# Try without SSL
test_connection(remove_sslmode(DATABASE_URL), "Main DB without SSL")
