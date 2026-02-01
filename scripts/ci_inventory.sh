#!/usr/bin/env bash
# ci_inventory.sh - YAML dynamic inventory
cat <<EOF
all:
  hosts:
    edgepaas-ec2:
      ansible_host: "${EC2_IP}"
      ansible_user: "ec2-user"
      ansible_private_key_file: "${SSH_PRIVATE_KEY}"
      ansible_python_interpreter: "/usr/bin/python3"
EOF
