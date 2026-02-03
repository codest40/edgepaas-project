#!/usr/bin/env python3
"""
Post-startup verification:
- DB connectivity
- Alembic migration state
Send alert if anything is wrong.
"""

import os
import sys
import requests
from sqlalchemy import create_engine, text
from alembic.config import Config
from alembic.script import ScriptDirectory
from alembic.runtime.migration import MigrationContext

DATABASE_URL = os.getenv("DATABASE_URL")
ALERT_WEBHOOK = os.getenv("ALERT_WEBHOOK_URL")

def alert(message: str):
    print(f"[ALERT] {message}", file=sys.stderr)

    if ALERT_WEBHOOK:
        try:
            requests.post(
                ALERT_WEBHOOK,
                json={"text": message},
                timeout=5,
            )
        except Exception as e:
            print(f"[ALERT] Failed to send webhook: {e}", file=sys.stderr)

def check_db():
    engine = create_engine(DATABASE_URL)
    with engine.connect() as conn:
        conn.execute(text("SELECT 1"))

def check_migrations():
    alembic_cfg = Config("alembic.ini")
    script = ScriptDirectory.from_config(alembic_cfg)

    engine = create_engine(DATABASE_URL)
    with engine.connect() as conn:
        context = MigrationContext.configure(conn)
        current_rev = context.get_current_revision()
        head_rev = script.get_current_head()

    if current_rev != head_rev:
        raise RuntimeError(
            f"Alembic mismatch: current={current_rev}, head={head_rev}"
        )

def main():
    try:
        check_db()
        check_migrations()
        print("[VERIFY] DB connectivity OK")
        print("[VERIFY] Alembic migrations OK")
        print("[VERIFY] Startup verification PASSED")
    except Exception as e:
        alert(f"Startup verification FAILED: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
