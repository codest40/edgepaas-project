#!/usr/bin/env bash
# runner.sh - Terraform runner (init, fmt, validate, plan, apply, destroy)

set -euo pipefail

ACTION="${1:-apply}"   # default action = apply
DIR="${2:-.}"          # default directory = current folder

# ----------------------------
# Paths
# ----------------------------
ROOT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
IAC_DIR="$ROOT_DIR/iac"
ANSIBLE_DIR="$ROOT_DIR/ansible"
GIT_WORKFLOW_DIR="$ROOT_DIR/.github/workflows"
DOCKER_DIR="$ROOT_DIR/docker"
SCRIPTS_DIR="$ROOT_DIR/scripts"

if [[ ! -d "$DIR" ]]; then
  echo "❌ Directory not found: $DIR"
  exit 1
fi

cd "$DIR"

run_apply() {
  echo " Running Terraform APPLY in: $(pwd)"
  echo "Did You Update Your current Laptop IP??"
  terraform init
  terraform fmt -recursive
  terraform validate
  terraform plan
  terraform apply --auto-approve
  echo "✅ APPLY complete. Updating Ansible Inventry..."
  chmod +x "$SCRIPTS_DIR"/update-inventory.sh
  bash "$SCRIPTS_DIR"/update-inventory.sh
  echo "Running Ansible Scripts..."
  chmod +x "$SCRIPTS_DIR"/activate-ansible.sh
  bash  "$SCRIPTS_DIR"/activate-ansible.sh
}

run_destroy() {
  echo " Running Terraform DESTROY in: $(pwd)"

  terraform init
  terraform validate
  terraform destroy --auto-approve -lock=false #To ensure destroy happes

  echo "✅ DESTROY complete."
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
    echo "Usage:"
    echo "  ./runner.sh apply   [DIR]"
    echo "  ./runner.sh destroy [DIR]"
    exit 1
    ;;
esac

