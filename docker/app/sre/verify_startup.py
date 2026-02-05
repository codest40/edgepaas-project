# app/sre/verify_startup.py
import os
import time
import sys
from sqlalchemy import create_engine, text
from alembic.config import Config
from alembic.script import ScriptDirectory
from alembic.runtime.migration import MigrationContext
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))
from logger import logger
from send_alert import send_alert
from wait_for_db import DATABASE_URL


def check_db():
    start = time.time()
    engine = create_engine(DATABASE_URL)

    with engine.connect() as conn:
        conn.execute(text("SELECT 1"))

    logger.info(f"✅ DB connectivity OK ({time.time() - start:.2f}s)")


def check_migrations():
    start = time.time()

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

    logger.info(f"✅ Alembic migrations OK ({time.time() - start:.2f}s)")


def run_startup_checks():
    check_db()
    check_migrations()


def main():
    try:
        run_startup_checks()
        logger.info("✅ Startup verification PASSED")
    except Exception as e:
        logger.error("❌ Startup verification FAILED")
        send_alert(f"Startup verification failed: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
