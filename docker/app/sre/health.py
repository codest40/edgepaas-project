# app/sre/health.py
import os
import sys
from fastapi import APIRouter, status
from fastapi.responses import JSONResponse

# Ensure imports work regardless of working directory
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), ".")))
from logger import logger
from verify_startup import check_db, check_migrations

router = APIRouter()

@router.get("/health/live")
def liveness():
    """
    Liveness probe: returns 200 OK if the app process is running.
    """
    logger.info("Liveness check OK ✅")
    return JSONResponse(
        status_code=status.HTTP_200_OK,
        content={"status": "alive", "icon": "✅", "message": "App is running"}
    )


@router.get("/health/ready")
def readiness():
    """
    Readiness probe: returns 200 OK if DB connectivity and Alembic migrations are OK.
    Returns 503 if any check fails.
    """
    try:
        check_db()
        check_migrations()
        logger.info("Readiness check OK ✅")
        return JSONResponse(
            status_code=status.HTTP_200_OK,
            content={"status": "ready", "icon": "✅", "message": "DB and migrations OK"}
        )
    except Exception as e:
        logger.error(f"Readiness check FAILED ❌: {e}")
        return JSONResponse(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            content={"status": "not ready", "icon": "❌", "message": str(e)}
        )
