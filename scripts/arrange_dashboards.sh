#!/bin/bash
DASH_DIR="/var/lib/docker/monitoring/grafana/dashboards"

if ! command -v jq >/dev/null 2>&1; then
  sudo yum install -y jq
fi

find "$DASH_DIR" -name '*.json' | while read f; do
  # Only unwrap if 'title' is missing at top level
  if ! jq -e 'has("title")' "$f" >/dev/null; then
    tmp=$(mktemp)
    # Merge 'dashboard' object into top-level while preserving other keys
    jq '{title: .dashboard.title, uid: .dashboard.uid, schemaVersion: .dashboard.schemaVersion, version: .dashboard.version, panels: .dashboard.panels, overwrite: true} + (del(.dashboard))' "$f" > "$tmp" \
      && sudo mv "$tmp" "$f"
    echo "Unwrapped $f"
  else
    echo "Skipped $f (already unwrapped)"
  fi
done

echo "Ensuring every file has deploy ownership"
sudo chown deploy:deploy /var/lib/docker/monitoring/grafana/dashboards/*.json
sudo chmod 644 /var/lib/docker/monitoring/grafana/dashboards/*.json
