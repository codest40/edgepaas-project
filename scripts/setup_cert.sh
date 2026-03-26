#!/bin/bash
set -euo pipefail

DOMAIN=${DOMAIN:-edgepaas.duckdns.org}
EMAIL=${EMAIL_TO:-}
BOOTSTRAP_FLAG=/opt/edgepaas/FIRST_RUN_DONE
CERTBOT_BIN=$(which certbot || echo "/usr/local/bin/certbot")
CERT_FILE="/etc/letsencrypt/live/$DOMAIN/fullchain.pem"
DUCKDNS_TOKEN=${DUCKDNS_TOKEN:-}

# -----------------------------
# Validate environment
# -----------------------------
if [[ -z "$EMAIL" ]]; then
  echo "❌ No email provided. Please set EMAIL_TO environment variable."
  exit 1
fi

if [[ -z "$DUCKDNS_TOKEN" ]]; then
  echo "❌ No DuckDNS token provided. Please set DUCKDNS_TOKEN environment variable."
  exit 1
fi

if [[ ! -x "$CERTBOT_BIN" ]]; then
  echo "❌ Certbot not found at $CERTBOT_BIN"
  exit 1
fi

sudo mkdir -p /opt/edgepaas

# -----------------------------
# Prepare DuckDNS credentials for certbot DNS plugin
# -----------------------------
DUCKDNS_INI=/opt/edgepaas/duckdns.ini
sudo tee "$DUCKDNS_INI" > /dev/null <<EOF
dns_duckdns_token = $DUCKDNS_TOKEN
EOF
sudo chmod 600 "$DUCKDNS_INI"

# -----------------------------
# First-run: issue cert if missing or invalid
# -----------------------------
if [[ ! -f "$BOOTSTRAP_FLAG" ]]; then
    echo "First run detected."

    # Check if cert exists and is valid
    if [[ -f "$CERT_FILE" ]] && sudo openssl x509 -checkend 0 -noout -in "$CERT_FILE"; then
        echo "✅ Certificate already exists and valid, skipping issuance."
    else
        echo "❌ Certificate missing or invalid, issuing via DuckDNS DNS-01..."
        sudo "$CERTBOT_BIN" certonly \
          --authenticator dns-duckdns \
          --dns-duckdns-credentials "$DUCKDNS_INI" \
          --dns-duckdns-propagation-seconds 30 \
          -d "$DOMAIN" \
          --non-interactive \
          --agree-tos \
          -m "$EMAIL"
    fi

    sudo touch "$BOOTSTRAP_FLAG"
    echo "Reloading Nginx to pick up certificate..."
    sudo systemctl start nginx || true
    sudo systemctl reload nginx || true
else
    echo "✅ First run already completed, skipping certificate issuance."
fi

echo "✅ SSL setup complete for $DOMAIN"
