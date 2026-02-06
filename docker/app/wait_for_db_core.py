#!/usr/bin/env python3
"""
Core DB wait logic.
Try a single DB URL multiple times.
"""

import time
import psycopg2
from local_tz import timer

def wait_for_database(db_url: str, max_retries: int = 5, retry_interval: int = 3) -> None:
    """
    Wait for a PostgreSQL database to be ready.
    Raises RuntimeError if not reachable after max_retries.
    """
    start = time.time()
    for attempt in range(1, max_retries + 1):
        now_str = timer()
        print(f"[WAIT_FOR_DB_CORE: {now_str}] Attempt {attempt}/{max_retries} connecting to: {db_url}")
        try:
            conn = psycopg2.connect(db_url)
            conn.close()
            end = time.time()
            print(f"[WAIT_FOR_DB_CORE] Database ready after {end - start:.2f}s")
            return
        except psycopg2.OperationalError as e:
            print(f"[WAIT_FOR_DB_CORE] Database not ready: {e}")
            if attempt < max_retries:
                time.sleep(retry_interval)
            else:
                end = time.time()
                raise RuntimeError(
                    f"[WAIT_FOR_DB_CORE] Could not connect after {max_retries} retries "
                    f"(waited {end - start:.2f}s)"
                )
