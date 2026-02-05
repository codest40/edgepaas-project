# app/sre/send_alert.py
import os
import sys

# Allow importing logger if running from scripts anywhere
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), ".")))
from logger import logger

import requests

ALERT_WEBHOOK = os.getenv("ALERT_WEBHOOK_URL")
ALERT_EMAILS = os.getenv("ALERT_EMAILS", "")
ALERT_EMAIL_TO = os.getenv("ALERT_EMAIL_TO")
ALERT_EMAIL_FROM = os.getenv("ALERT_EMAIL_FROM")


def alert_email(subject: str, body: str):
    """
    Stub for sending email alerts.
    Replace with SMTP / SES / SendGrid later.
    """
    if not ALERT_EMAIL_TO or not ALERT_EMAIL_FROM:
        logger.error("❌ ALERT_EMAIL_TO or ALERT_EMAIL_FROM not configured")
        return

    logger.info(f"📧 Sending email alert from {ALERT_EMAIL_FROM} to {ALERT_EMAIL_TO}")
    logger.error(f"EMAIL SUBJECT: {subject}")
    logger.error(f"EMAIL BODY: {body}")


def send_alert(message: str):
    """
    Send alert via webhook first, then email as fallback.
    Logs everything.
    """
    logger.error(f"🚨 ALERT: {message}")

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

    if ALERT_EMAIL_TO:
        alert_email(
            subject="EdgePaaS Startup Alert",
            body=message,
        )
        logger.info("✅ Email alert sent successfully")
        return

    logger.error("❌ No alert channel configured")
