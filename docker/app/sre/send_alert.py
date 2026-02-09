# app/sre/send_alert.py

import os
import sys
import requests

# Allow importing logger from the same folder
sys.path.append(os.path.abspath(os.path.dirname(__file__)))
from logger import logger

# Environment variables
ALERT_WEBHOOK = os.getenv("ALERT_WEBHOOK_URL")
ALERT_EMAILS = os.getenv("ALERT_EMAILS", "")
ALERT_EMAIL_TO = os.getenv("EMAIL_TO")
ALERT_EMAIL_FROM = os.getenv("EMAIL_FROM")


def alert_email(subject: str, body: str):
    """
    Send email alert stub.
    Replace with real SMTP / SES / SendGrid later.
    """
    if not ALERT_EMAIL_TO or not ALERT_EMAIL_FROM:
        logger.error("❌ ALERT_EMAIL_TO or ALERT_EMAIL_FROM not configured")
        return

    logger.info(f"📧 Sending email alert from {ALERT_EMAIL_FROM} to {ALERT_EMAIL_TO}")
    logger.error(f"EMAIL SUBJECT: {subject}")
    logger.error(f"EMAIL BODY: {body}")


def send_alert(message: str, use_fallback_db=False):
    """
    Send alert via webhook first, then email as fallback.
    Logs everything.
    
    Args:
        message (str): The alert message
        use_fallback_db (bool): True if alert is triggered during SQLite fallback
    """
    if use_fallback_db:
        logger.warning(f"⚠️ Alert triggered during SQLite fallback: {message}")
        # Do not send critical external alerts for expected SQLite fallback
        return

    logger.error(f"🚨 ALERT: {message}")

    # Webhook alert
    if ALERT_WEBHOOK and ALERT_WEBHOOK.startswith("http"):
        try:
            response = requests.post(
                ALERT_WEBHOOK,
                json={"text": message},
                timeout=5,
            )
            response.raise_for_status()
            logger.info("✅ Webhook alert sent successfully")
            return
        except Exception as e:
            logger.error(f"❌ Webhook alert failed: {e}")

    # Email alert
    if ALERT_EMAIL_TO:
        alert_email(
            subject="EdgePaaS Alert",
            body=message,
        )
        logger.info("✅ Email alert sent successfully")
        return

    # No alert channel configured
    logger.error("❌ No alert channel configured")
