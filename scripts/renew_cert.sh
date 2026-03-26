#!/bin/bash
set -euo pipefail

DOMAIN="edgepaas.duckdns.org"

# Check if cert expires within 30 days
EXPIRY=$(sudo certbot certificates | grep "Expiry Date" | grep "$DOMAIN" | awk '{print $4}')
EXPIRY_SECONDS=$(date -d "$EXPIRY" +%s)
NOW_SECONDS=$(date +%s)
DAYS_LEFT=$(( ($EXPIRY_SECONDS - $NOW_SECONDS) / 86400 ))

if [ $DAYS_LEFT -le 30 ]; then
    echo "Certificate for $DOMAIN expires in $DAYS_LEFT days — renewing..."
    bash /home/ec2-user/setup_ssl.sh
else
    echo "✅ Certificate for $DOMAIN is valid for $DAYS_LEFT more days — skipping renewal"
fi
