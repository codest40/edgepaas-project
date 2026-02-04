# app/sre/send_alert.py
import os
import requests
from logger import logger

ALERT_WEBHOOK = os.getenv("ALERT_WEBHOOK_URL")
ALERT_EMAIL_TO = os.getenv("ALERT_EMAIL_TO")


def alert_email(subject: str, body: str):
    """
    Stub for email alerting.
    Replace with SMTP / SES / SendGrid later.
    """
    logger.info(f"📧 Sending email alert to {ALERT_EMAIL_TO}")
    logger.error(f"EMAIL SUBJECT: {subject}")
    logger.error(f"EMAIL BODY: {body}")


def send_alert(message: str):
    logger.error(f"🚨 ALERT: {message}")

    if ALERT_WEBHOOK and ALERT_WEBHOOK.startswith("http"):
        try:
            requests.post(
                ALERT_WEBHOOK,
                json={"text": message},
                timeout=5,
            )
            logger.info("✅ Webhook alert sent")
            return
        except Exception as e:
            logger.error(f"❌ Webhook alert failed: {e}")

    if ALERT_EMAIL_TO:
        alert_email(
            subject="EdgePaaS Startup Alert",
            body=message,
        )
        logger.info("✅ Email alert sent")
        return

    logger.error("❌ No alert channel configured")
