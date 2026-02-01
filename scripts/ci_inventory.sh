#!/usr/bin/env bash
# ci_inventory.sh - dynamic inventory for CI/CD

if [[ -z "${EC2_IP:-}" || -z "${SSH_PRIVATE_KEY:-}" ]]; then
  echo "Error: EC2_IP or SSH_KEY not set" >&2
  exit 1
fi

# output JSON
cat <<EOF
{
  "all": {
    "hosts": ["edgepaas-ec2"],
    "vars": {}
  },
  "_meta": {
    "hostvars": {
      "edgepaas-ec2": {
        "ansible_host": "${EC2_IP}",
        "ansible_user": "ec2-user",
        "ansible_private_key_file": "${SSH_PRIVATE_KEY}",
        "ansible_python_interpreter": "/usr/bin/python3"
      }
    }
  }
}
EOF
