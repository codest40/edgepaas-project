#!/bin/bash
# =============================================================================
# Local Postgres setup for EdgePaaS (Amazon Linux 2023)
# Logs all steps to /var/log/edgepaas/local_postgres.log
# =============================================================================
set -euo pipefail

LOG_FILE="/var/log/edgepaas/local_postgres.log"

# Ensure log directory exists
sudo mkdir -p $(dirname "$LOG_FILE")
sudo touch "$LOG_FILE"
sudo chown $USER:$USER "$LOG_FILE"

# Function to log output
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') | $*" | tee -a "$LOG_FILE"
}

# Function to run commands and log errors
run_cmd() {
    local CMD="$*"
    log "RUNNING: $CMD"
    if ! eval "$CMD" >>"$LOG_FILE" 2>&1; then
        log "ERROR: Command failed -> $CMD"
        exit 1
    fi
}

log "=== Starting Local Postgres Setup ==="

# Install Postgres
log "Installing Postgres..."
run_cmd "sudo dnf update -y"
run_cmd "sudo dnf install -y postgresql-server postgresql-contrib"

# Initialize DB
log "Initializing Postgres database cluster..."
run_cmd "sudo postgresql-setup --initdb"

# Enable & start service
log "Enabling and starting Postgres service..."
run_cmd "sudo systemctl enable postgresql"
run_cmd "sudo systemctl start postgresql"

# Create test user & database
log "Creating test user and database..."
run_cmd "sudo -u postgres psql <<EOF
DO
\$do\$
BEGIN
   IF NOT EXISTS (
      SELECT FROM pg_catalog.pg_user WHERE usename = 'testuser'
   ) THEN
      CREATE USER testuser WITH PASSWORD 'testpass';
   END IF;
END
\$do\$;

DO
\$do\$
BEGIN
   IF NOT EXISTS (
      SELECT FROM pg_database WHERE datname = 'testdb'
   ) THEN
      CREATE DATABASE testdb OWNER testuser;
   END IF;
END
\$do\$;

GRANT ALL PRIVILEGES ON DATABASE testdb TO testuser;
EOF"

# Configure password authentication
log "Configuring password authentication..."
PG_HBA="/var/lib/pgsql/data/pg_hba.conf"
run_cmd "sudo sed -i 's/local\s*all\s*all\s*peer/local all all md5/' $PG_HBA"
run_cmd "sudo systemctl restart postgresql"

# Write .env.test
log "Writing .env.test file..."
run_cmd "echo 'DATABASE_URL_TEST=postgresql://testuser:testpass@localhost:5432/testdb' > .env.test"

log "✅ Local test Postgres setup complete!"
