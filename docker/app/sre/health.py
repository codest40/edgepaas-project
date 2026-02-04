# health.py
from fastapi import APIRouter, status
from fastapi.responses import JSONResponse
from verify_startup import check_db, check_migrations
from config_log import logger

router = APIRouter()

@router.get("/health/live")
def liveness():
    """
    Liveness probe: returns 200 OK if app is running.
    """
    logger.info("Liveness check OK ✅")
    return JSONResponse(
        status_code=status.HTTP_200_OK,
        content={"status": "alive", "icon": "✅", "message": "App is running"}
    )

@router.get("/health/ready")
def readiness():
    """
    Readiness probe: returns 200 OK if DB + migrations are OK.
    Returns 503 if anything fails.
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
