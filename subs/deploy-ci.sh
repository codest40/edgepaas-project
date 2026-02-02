#!/bin/bash
set -euo pipefail

# Clone or update repo
if [ ! -d ~/edgepaas ]; then
  git clone https://github.com/YOUR_USERNAME/edgepaas.git ~/edgepaas
else
  cd ~/edgepaas
  git fetch --all
  git reset --hard origin/main
fi

cd ~/edgepaas/ansible

# Create temporary inventory
cat > /tmp/ci_inventory.yml <<EOF
all:
  hosts:
    edgepaas:
      ansible_host: "${EC2_IP}"
      ansible_user: ec2-user
      ansible_python_interpreter: /usr/bin/python3
      ansible_ssh_args: '-o StrictHostKeyChecking=no'
EOF

export ANSIBLE_ROLES_PATH=./roles
export DATABASE_URL="${DATABASE_URL}"
export OPENWEATHER_API_KEY="${OPENWEATHER_API_KEY}"
export RUN_MIGRATIONS="${RUN_MIGRATIONS}"
export DOCKER_USER="${DOCKER_USER}"
export ANSIBLE_HOST_KEY_CHECKING=False

# Run Ansible
ansible-playbook -i /tmp/ci_inventory.yml playbooks/setup_docker.yml
ansible-playbook -i /tmp/ci_inventory.yml playbooks/deploy_app.yml \
  -e "dockerhub_user=${DOCKER_USER}" \
  -e "app_name=edgeapp" \
  -e "DATABASE_URL=${DATABASE_URL}" \
  -e "OPENWEATHER_API_KEY=${OPENWEATHER_API_KEY}" \
  -e "RUN_MIGRATIONS=${RUN_MIGRATIONS}"
