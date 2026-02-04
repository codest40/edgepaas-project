# app/sre/logger.py
import logging
import os
from logging.handlers import RotatingFileHandler

LOG_PATH = "/opt/edgepaas/logger.log"
LOG_LEVEL = os.getenv("LOG_LEVEL", "INFO").upper()

os.makedirs(os.path.dirname(LOG_PATH), exist_ok=True)

logger = logging.getLogger("edgepaas")
logger.setLevel(LOG_LEVEL)

formatter = logging.Formatter(
    fmt="%(asctime)s | %(levelname)s | %(name)s | %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
)

# File handler (rotates)
file_handler = RotatingFileHandler(
    LOG_PATH,
    maxBytes=5 * 1024 * 1024,  # 5MB
    backupCount=5,
)
file_handler.setFormatter(formatter)

# Console handler
console_handler = logging.StreamHandler()
console_handler.setFormatter(formatter)

# Avoid duplicate handlers
if not logger.handlers:
    logger.addHandler(file_handler)
    logger.addHandler(console_handler)
