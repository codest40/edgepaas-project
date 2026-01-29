#!/bin/bash
# EdgePaaS: update Ansible inventory with Terraform EC2 public IP

# Path to inventory file
INVENTORY_FILE="../ansible/inventory/hosts.yml"

# Get public IP from Terraform
EC2_IP=$(terraform -chdir=../iac output -raw ec2_public_ips | jq -r '."public_app"')

if [[ -z "$EC2_IP" ]]; then
  echo "Error: Could not fetch EC2 public IP from Terraform output."
  exit 1
fi

# Write inventory
cat > "$INVENTORY_FILE" <<EOL
all:
  hosts:
    edgepaas-ec2:
      ansible_host: $EC2_IP
      ansible_user: ec2-user
      ansible_private_key_file: files/tf-web-key.pem
      ansible_python_interpreter: /usr/bin/python3
EOL

echo "Ansible inventory updated: $EC2_IP"
