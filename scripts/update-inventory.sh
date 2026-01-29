#!/bin/bash
# EdgePaaS: Update Ansible inventory & run Ansible playbooks (local + CI/CD safe)
# Auto-detect EC2 IP, wait for readiness, update inventory, run playbooks
set -euo pipefail

# ----------------------------
# Paths
# ----------------------------
ROOT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
ANSIBLE_DIR="$ROOT_DIR/ansible"
IAC_DIR="$ROOT_DIR/iac"
INVENTORY_FILE="$ANSIBLE_DIR/inventory/hosts.yml"
REPO="codest40/edgepass-project"  # GitHub repo for secret update
APP_TAG="edgepaas-public-app"

# ----------------------------
# Determine EC2 public IP
# ----------------------------
if [[ -n "${EC2_IP:-}" ]]; then
    echo "🔹 Using EC2_IP from environment / GitHub secret: $EC2_IP"
elif [[ -x "$(command -v terraform)" ]]; then
    echo "🔹 Fetching EC2 public IP from Terraform output (local)..."
    EC2_IP=$(terraform -chdir="$IAC_DIR" output -json ec2_public_ips | jq -r '."public_app"')
elif [[ -x "$(command -v aws)" ]]; then
    echo "🔹 Fetching EC2 public IP via AWS CLI (CI/CD)..."
    EC2_IP=$(aws ec2 describe-instances \
        --filters "Name=tag:Name,Values=$APP_TAG" \
        --query "Reservations[0].Instances[0].PublicIpAddress" \
        --output text)
else
    echo "❌ Cannot determine EC2 IP: Terraform or AWS CLI not found and EC2_IP not set"
    exit 1
fi

if [[ -z "$EC2_IP" || "$EC2_IP" == "null" || "$EC2_IP" == "None" ]]; then
    echo "❌ Error: Could not determine EC2 public IP."
    exit 1
fi

echo "🔹 EC2 Public IP: $EC2_IP"

# ----------------------------
# Wait for EC2 instance to be ready
# ----------------------------
echo "🔹 Waiting for EC2 instance to be ready: $EC2_IP"
MAX_RETRIES=3
SLEEP_SEC=5
COUNT=0

while true; do
    if nc -z -w5 "$EC2_IP" 80 &> /dev/null; then
        echo "✅ HTTP port is open on $EC2_IP"
        break
    fi
    COUNT=$((COUNT+1))
    if [[ $COUNT -ge $MAX_RETRIES ]]; then
        echo "❌ EC2 instance NOT Reachable"
        break
    fi
    echo " Waiting for HTTP on $EC2_IP... ($COUNT/$MAX_RETRIES)"
    sleep $SLEEP_SEC
done

# ----------------------------
# Update GitHub secret (CI/CD only)
# ----------------------------
if [[ "${GITHUB_ACTIONS:-}" == "true" ]] && command -v gh &> /dev/null; then
    echo "$EC2_IP" | gh secret set EC2_IP --repo "$REPO" --body -
    echo "✅ GitHub secret EC2_IP updated"
else
  # ----------------------------
  # Write Ansible inventory
  # ----------------------------
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


fi

# ----------------------------
# Run Ansible playbooks
# ----------------------------
echo "🔹 Running Ansible playbooks..."
cd "$ANSIBLE_DIR"
export ANSIBLE_ROLES_PATH=./roles
export dockerhub_user="${DOCKER_USER:-codest40}"

ansible-playbook -i inventory/hosts.yml playbooks/setup_docker.yml
ansible-playbook -i inventory/hosts.yml playbooks/deploy_app.yml \
    --extra-vars "active_color=${ACTIVE_COLOR:-green} inactive_color=${INACTIVE_COLOR:-blue} active_port=8081 inactive_port=8080"

echo "✅ Ansible playbooks completed"
