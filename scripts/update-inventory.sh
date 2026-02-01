#!/bin/bash
# EdgePaaS: CI/CD-safe update inventory & deploy script
# Checks updates inventory, runs Ansible

set -euo pipefail

ROOT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
ANSIBLE_DIR="$ROOT_DIR/ansible"
INVENTORY_FILE="$ANSIBLE_DIR/inventory/hosts.yml"
APP_TAG="edgepaas-public-app"
SCRIPTS_DIR="$ROOT_DIR/scripts"

# ----------------------------
# Determine EC2 public IP
# ----------------------------
if [[ -n "${EC2_IP:-}" ]]; then
    echo "🔹 Using EC2_IP from environment: $EC2_IP"
elif command -v aws &> /dev/null; then
    echo "🔹 Fetching EC2 public IP via AWS CLI..."
    EC2_IP=$(aws ec2 describe-instances \
        --filters "Name=tag:Name,Values=$APP_TAG" \
        --query "Reservations[].Instances[] | [?State.Name=='running'].PublicIpAddress | [0]" \
        --output text)
else
    echo "❌ EC2_IP not set and AWS CLI not available"
    exit 1
fi

if [[ -z "$EC2_IP" || "$EC2_IP" == "null" || "$EC2_IP" == "None" ]]; then
    echo "❌ Could not determine EC2 public IP."
    exit 1
fi
echo "🔹 EC2 Public IP: $EC2_IP"

# ----------------------------
# Wait for HTTP readiness
# ----------------------------
MAX_RETRIES=3
SLEEP_SEC=5
COUNT=0
echo "🔹 Waiting for HTTP port 80..."
while ! nc -z -w5 "$EC2_IP" 80 &> /dev/null; do
    COUNT=$((COUNT+1))
    if [[ $COUNT -ge $MAX_RETRIES ]]; then
        echo "❌ HTTP not ready after $MAX_RETRIES tries"
        break
    fi
    echo " Waiting for HTTP on $EC2_IP... ($COUNT/$MAX_RETRIES)"
    sleep $SLEEP_SEC
done

# ----------------------------
# Local vs CI inventory
# ----------------------------
if [[ -z "${GITHUB_ACTIONS:-}" ]]; then
    source "$SCRIPTS_DIR/.env"
    # Local: write inventory file
    SSH_KEY="$ANSIBLE_DIR/roles/app/files/tf-web-key.pem"
    cat > "$INVENTORY_FILE" <<EOF
all:
  hosts:
    edgepaas-ec2:
      ansible_host: "$EC2_IP"
      ansible_user: "ec2-user"
      ansible_private_key_file: "$SSH_KEY"
      ansible_python_interpreter: "/usr/bin/python3"
EOF
else
    # CI: use dynamic inventory from env
    INVENTORY_FILE="$ROOT_DIR/scripts/ci_inventory.sh"
    chmod +x "$INVENTORY_FILE"
    OPENWEATHER_API_KEY="${OPENWEATHER_API_KEY}"
fi

echo "✅ Inventory ready: $INVENTORY_FILE"
ansible-inventory -i "$INVENTORY_FILE" --list

# ----------------------------
# Run Ansible playbooks
# ----------------------------
cd "$ANSIBLE_DIR"
export ANSIBLE_ROLES_PATH=./roles
export ${DOCKER_USER:-codest40}
export ${DATABASE_URL}
export ${OPENWEATHER_API_KEY}
export RUN_MIGRATIONS=true

ansible-playbook -i "$INVENTORY_FILE" playbooks/setup_docker.yml
ansible-playbook -i "$INVENTORY_FILE" playbooks/deploy_app.yml \
    --extra-vars "dockerhub_user=codest40 app_name=edgeapp DATABASE_URL=$DATABASE_URL OPENWEATHER_API_KEY=$OPENWEATHER_API_KEY RUN_MIGRATIONS=true"

echo "✅ Playbooks completed"
