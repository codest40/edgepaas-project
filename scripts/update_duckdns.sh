#!/bin/bash
set -euo pipefail

TOKEN="${DUCKDNS_TOKEN:?❌ DUCKDNS_TOKEN is required}"
DOMAIN="edgepaas"


IP=$(curl -s http://checkip.amazonaws.com)

echo "Updating DuckDNS: $DOMAIN -> $IP"
curl -s "https://www.duckdns.org/update?domains=$DOMAIN&token=$TOKEN&ip=$IP"

echo "✅ DuckDNS update complete"
