#!/bin/bash
# EdgePaaS: CI/CD-safe update inventory & deploy script
# Checks HTTP readiness instead of SSH, updates inventory, runs Ansible
set -euo pipefail

# ----------------------------
# Configurable paths & vars
# ----------------------------
ROOT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
ANSIBLE_DIR="$ROOT_DIR/ansible"
INVENTORY_FILE="$ANSIBLE_DIR/inventory/hosts.yml"
REPO="codest40/edgepaas-project"    # GitHub repo for secret update
APP_TAG="edgepaas-public-app"
MAX_RETRIES=3
SLEEP_SEC=5

# ----------------------------
# Determine EC2 public IP
# ----------------------------
if [[ -n "${EC2_IP:-}" ]]; then
    echo "🔹 Using EC2_IP from environment / GitHub secret: $EC2_IP"
elif [[ -x "$(command -v aws)" ]]; then
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
# Wait for HTTP port readiness
# ----------------------------
echo "🔹 Waiting for app to respond on HTTP port 80..."
COUNT=0
while true; do
    if nc -z -w5 "$EC2_IP" 80 &> /dev/null; then
        echo "✅ HTTP port is open on $EC2_IP"
        break
    fi
    COUNT=$((COUNT+1))
    if [[ $COUNT -ge $MAX_RETRIES ]]; then
        echo "❌ EC2 instance NOT reachable on HTTP yet"
        break
    fi
    echo " Waiting for HTTP on $EC2_IP... ($COUNT/$MAX_RETRIES)"
    sleep $SLEEP_SEC
done

# ----------------------------
# Write Ansible inventory
# ----------------------------
SSH_KEY="$ANSIBLE_DIR/roles/app/files/tf-web-key.pem"  # local key for Ansible (CI/CD-safe)
cat > "$INVENTORY_FILE" <<EOL
all:
  hosts:
    edgepaas-ec2:
      ansible_host: $EC2_IP
      ansible_user: ec2-user
      ansible_private_key_file: $SSH_KEY
      ansible_python_interpreter: /usr/bin/python3
EOL
echo "✅ Ansible inventory updated: $INVENTORY_FILE"

# ----------------------------
# Update GitHub secret (CI/CD only)
# ----------------------------
if [[ "${GITHUB_ACTIONS:-}" == "true" ]] && command -v gh &> /dev/null; then
  if [[ -n "$GH_TOKEN" ]]; then
    echo "✅ GH_TOKEN KEY IS DETECTED"
  fi
  if echo "$EC2_IP" | gh secret set EC2_IP --repo "$REPO" --body -; then
    echo "✅ GitHub secret EC2_IP updated"
  else
    echo "❌ Cannot set GitHub secret EC2_IP"
    exit 1
  fi
fi

# ----------------------------
# Run Ansible playbooks
# ----------------------------
echo "🔹 Running Ansible playbooks..."
cd "$ANSIBLE_DIR"
export ANSIBLE_ROLES_PATH=./roles
export dockerhub_user="${DOCKER_USER:-codest40}"
export DATABASE_URL=postgresql://edgepaas_db_user:gAgGcQzVqAKp7eA30fyWLY8WqAnYMpjh@dpg-d5ukoekhg0os73b0261g-a.virginia-postgres.render.com/edgepaas_db
export OPENWEATHER_API_KEY=c07845bbeac990f8729cee1469389397
export RUN_MIGRATIONS=true

ansible-playbook -i inventory/hosts.yml playbooks/setup_docker.yml
ansible-playbook -i inventory/hosts.yml playbooks/deploy_app.yml \
  --extra-vars "dockerhub_user=codest40 app_name=edgeapp active_color=blue inactive_color=green active_port=8080 inactive_port=8081 DATABASE_URL=postgresql://edgepaas_db_user:gAgGcQzVqAKp7eA30fyWLY8WqAnYMpjh@dpg-d5ukoekhg0os73b0261g-a.virginia-postgres.render.com/edgepaas_db OPENWEATHER_API_KEY=c07845bbeac990f8729cee1469389397 RUN_MIGRATIONS=true"

echo "✅ Ansible playbooks completed"
