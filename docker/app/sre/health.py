# app/sre/health.py

from fastapi import APIRouter, status
from fastapi.responses import JSONResponse

from app.sre.logger import logger
from app.sre.verify_startup import check_db, check_migrations
from wait_for_db import DATABASE_URL  # final chosen DB

router = APIRouter()


@router.get("/health/live")
def liveness():
    """
    Liveness probe.
    Confirms the app process is running.
    No dependency checks.
    """
    logger.info("Liveness check OK ✅")
    return JSONResponse(
        status_code=status.HTTP_200_OK,
        content={
            "status": "alive",
            "icon": "✅",
            "message": "App process is running"
        }
    )


@router.get("/health/ready")
def readiness():
    """
    Readiness probe.
    Confirms the app is ready to receive traffic.
    Checks:
      - DB connectivity
      - Alembic migration state (skipped for SQLite)
    """
    try:
        check_db()

        # Only run migrations check if using Postgres
        if not DATABASE_URL.startswith("sqlite"):
            check_migrations()
        else:
            logger.info("Readiness migrations check skipped (SQLite fallback) ✅")

        logger.info("Readiness check OK ✅")
        return JSONResponse(
            status_code=status.HTTP_200_OK,
            content={
                "status": "ready",
                "icon": "✅",
                "message": "Database and migrations are healthy"
            }
        )

    except Exception as exc:
        logger.error(f"Readiness check FAILED ❌: {exc}")
        return JSONResponse(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            content={
                "status": "not ready",
                "icon": "❌",
                "message": str(exc)
            }
        )
