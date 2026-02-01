#!/usr/bin/env bash
# dynamic inventory for booth CI/CD and local

cat > "$INVENTORY_FILE" <<EOF
all:
  hosts:
    edgepaas-ec2:
      ansible_host: "$EC2_IP"
      ansible_user: "ec2-user"
      ansible_private_key_file: "$SSH_KEY"
      ansible_python_interpreter: "/usr/bin/python3"
EOF
