# app/sre/health.py
from fastapi import APIRouter
from logger import logger
from verify_startup import run_startup_checks

router = APIRouter()

STARTUP_OK = False
STARTUP_ERROR = None


def init_startup_state():
    global STARTUP_OK, STARTUP_ERROR
    try:
        run_startup_checks()
        STARTUP_OK = True
    except Exception as e:
        STARTUP_ERROR = str(e)
        logger.error(f"Startup check failed during readiness init: {e}")


@router.get("/health")
def health():
    return {
        "status": "ok",
        "service": "edgepaas",
    }


@router.get("/ready")
def readiness():
    if not STARTUP_OK:
        return {
            "status": "not-ready",
            "reason": STARTUP_ERROR,
        }

    return {
        "status": "ready",
    }
