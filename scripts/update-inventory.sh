#!/bin/bash
# EdgePaaS: Update Ansible inventory & run Ansible playbooks (local + CI/CD safe)
set -euo pipefail

# ----------------------------
# Paths
# ----------------------------
ROOT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
ANSIBLE_DIR="$ROOT_DIR/ansible"
IAC_DIR="$ROOT_DIR/iac"
INVENTORY_FILE="$ANSIBLE_DIR/inventory/hosts.yml"
REPO="codest40/edgepass-project"  # GitHub repo for secret update

# ----------------------------
# Get EC2 public IP from Terraform
# ----------------------------
EC2_IP=$(terraform -chdir="$IAC_DIR" output -json ec2_public_ips | jq -r '."public_app"')

if [[ -z "$EC2_IP" || "$EC2_IP" == "null" ]]; then
    echo "❌ Error: Could not fetch EC2 public IP from Terraform output."
    exit 1
fi

echo "🔹 EC2 Public IP: $EC2_IP"

# ----------------------------
# Write Ansible inventory
# ----------------------------
cat > "$INVENTORY_FILE" <<EOL
all:
  hosts:
    edgepaas-ec2:
      ansible_host: $EC2_IP
      ansible_user: ec2-user
      ansible_private_key_file: $ANSIBLE_DIR/files/tf-web-key.pem
      ansible_python_interpreter: /usr/bin/python3
EOL

echo "✅ Ansible inventory updated: $INVENTORY_FILE"

# ----------------------------
# Update GitHub secret if running in CI/CD
# ----------------------------
if command -v gh &> /dev/null; then
    echo "$EC2_IP" | gh secret set EC2_IP --repo "$REPO" --body -
    echo "✅ GitHub secret EC2_IP updated"
fi

# ----------------------------
# Run Ansible playbooks
# ----------------------------
echo "🔹 Running Ansible playbooks..."
cd "$ANSIBLE_DIR"

ansible-playbook -i inventory/hosts.yml playbooks/setup_docker.yml
ansible-playbook -i inventory/hosts.yml playbooks/deploy_app.yml \
    --extra-vars "active_color=green inactive_color=blue active_port=8081 inactive_port=8080"

echo "✅ Ansible playbooks completed"
