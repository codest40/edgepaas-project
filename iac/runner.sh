#!/usr/bin/env bash
# EdgePaaS: Terraform runner (init, fmt, plan, apply, destroy)
# Runs locally

set -euo pipefail

ACTION="${1:-apply}"   # default = apply

# ----------------------------
# Paths
# ----------------------------
ROOT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
IAC_DIR="$ROOT_DIR/iac"
ANSIBLE_DIR="$ROOT_DIR/ansible"
SCRIPTS_DIR="$ROOT_DIR/scripts"
INV_FILE="$SCRIPTS_DIR/update-inventory.sh"

cd "$IAC_DIR"

run_apply() {
  echo "🔹 Terraform APPLY in: $(pwd)"
  terraform init
  terraform fmt -recursive
  terraform validate
  terraform plan
  terraform apply --auto-approve

  echo "🔹 Updating Ansible inventory..."
  cd "$SCRIPTS_DIR"
  bash "$INV_FILE"
}

run_destroy() {
  echo "🔹 Terraform DESTROY in: $(pwd)"
  terraform init
  terraform validate
  terraform destroy --auto-approve -lock=false
  echo "✅ DESTROY complete"
}

case "$ACTION" in
  apply)
    run_apply
    ;;
  destroy)
    run_destroy
    ;;
  *)
    echo "❌ Unknown action: $ACTION"
    echo "Usage: $0 [apply|destroy]"
    exit 1
    ;;
esac
