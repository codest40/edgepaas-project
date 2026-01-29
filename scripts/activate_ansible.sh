#!/bin/bash

ROOT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ANSIBLE_DIR="$ROOT_DIR/ansible"

echo "Running Ansible Scripts at $ANSIBLE_DIR"
cd "$ANSIBLE_DIR"
ansible-playbook -i inventory/hosts.yml playbooks/setup_docker.yml

ansible-playbook -i inventory/hosts.yml playbooks/deploy_app.yml \
  --extra-vars "active_color=green inactive_color=blue active_port=8081 inactive_port=8080"
