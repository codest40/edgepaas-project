#!/bin/bash
# Checks updates inventory, runs Ansible...

set -euo pipefail

ROOT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
ANSIBLE_DIR="$ROOT_DIR/ansible"
INVENTORY_FILE="$ANSIBLE_DIR/local.ini"
APP_TAG="edgepaas-public-app"
SCRIPTS_DIR="$ROOT_DIR/scripts"


# ----------------------------
# Determine EC2 public IP
# ----------------------------
if [[ -n "${EC2_IP:-}" ]]; then
    echo "🔹 Using EC2_IP from environment: $EC2_IP"
elif command -v aws &> /dev/null; then
    echo "🔹 Fetching EC2 public IP via AWS CLI..."
    EC2_IP=$(aws ec2 describe-instances \
        --filters "Name=tag:Name,Values=$APP_TAG" \
        --query "Reservations[].Instances[] | [?State.Name=='running'].PublicIpAddress | [0]" \
        --output text)
else
    echo "❌ EC2_IP not set and AWS CLI not available"
    exit 1
fi

if [[ -z "$EC2_IP" || "$EC2_IP" == "null" || "$EC2_IP" == "None" ]]; then
    echo "❌ Could not determine EC2 public IP."
    exit 1
fi
echo "🔹 EC2 Public IP: $EC2_IP"

# ----------------------------
# Wait for HTTP readiness
# ----------------------------
MAX_RETRIES=2
SLEEP_SEC=2
COUNT=0
echo "🔹 Waiting for HTTP port 80..."
while ! nc -z -w5 "$EC2_IP" 80 &> /dev/null; do
    COUNT=$((COUNT+1))
    if [[ $COUNT -ge $MAX_RETRIES ]]; then
        echo "❌ HTTP not ready after $MAX_RETRIES tries"
        break
    fi
    echo " Waiting for HTTP on $EC2_IP... ($COUNT/$MAX_RETRIES)"
    sleep $SLEEP_SEC
done

# ----------------------------
# Local vs CI inventory
# ----------------------------
if [[ -z "${GITHUB_ACTIONS:-}" ]]; then
    # Local: write inventory file
    SSH_KEY="$ANSIBLE_DIR/files/tf-web-key.pem"
    INVENTORY="$INVENTORY_FILE"
    ENV_FILE=".env"
    cat > "$INVENTORY" <<EOF
all:
  hosts:
    edgepaas_ec2:
      ansible_host: "$EC2_IP"
      ansible_user: "ec2-user"
      ansible_private_key_file: "$SSH_KEY"
      ansible_python_interpreter: "/usr/bin/python3"
      ansible_ssh_args: ' -o StrictHostKeyChecking=no'
EOF

    echo "✅ Local inventory ready: $INVENTORY"
    cd "$ANSIBLE_DIR"
    if [[ ! -f "$ENV_FILE" ]]; then
      echo "There is no ENV File Found. Exiting..."
      exit 1
    fi
    ansible-playbook -i "$INVENTORY" run.yml \
      --extra-vars "DOCKER_USER=$DOCKER_USER app_name=$APP_NAME DATABASE_URL=$DATABASE_URL OPENWEATHER_API_KEY=$OPENWEATHER_API_KEY RUN_MIGRATIONS=true"

else
    # CI/CD: use env vars directly, no inventory file
    if [[ -z "${SSH_PRIVATE_KEY:-}" ]]; then
        echo "❌ SSH_PRIVATE_KEY must be set in CI/CD secrets"
        exit 1
    fi

    mkdir -p ~/.ssh
    SSH_KEY_FILE="$HOME/.ssh/edgepaas_ci_key"
    HOST_FILE="$HOME/.ssh/edgepaas_ci_host"
    echo "$SSH_PRIVATE_KEY" > "$SSH_KEY_FILE"
    chmod 600 "$SSH_KEY_FILE"
  if [[ -n "$EC2_IP" ]]; then
  cat > "$HOST_FILE"  <<EOF
all:
  hosts:
    edgepaas-ec2:
      ansible_host: "$EC2_IP"
      ansible_user: "ec2-user"
      ansible_python_interpreter: "/usr/bin/python3"
      ansible_ssh_args: ' -o StrictHostKeyChecking=no'
EOF
      chmod 600 "$HOST_FILE"
      echo "✅ EC2 IP Found and $HOST_FILE Updated"
  else
      echo "❌ EC2 IP is NOT Found"
      exit 1
  fi

    cd "$ANSIBLE_DIR"
    if [[ ! -f "$ENV_FILE" ]]; then
      echo "❌ There is no ENV File Found. Exiting..."
      exit 1
    fi
    source "$ENV_FILE"
    export ANSIBLE_ROLES_PATH="$ANSIBLE_DIR/roles"
    export ANSIBLE_HOST_KEY_CHECKING=False
    export ANSIBLE_PRIVATE_KEY_FILE="$SSH_PRIVATE_KEY"
    INVENTORY="$ANSIBLE_DIR/inventory/ci.yml"

    ansible-playbook \
      -i "$HOST_FILE" \
      --private-key "$SSH_KEY_FILE" \
      playbooks/setup_docker.yml \
      -e dockerhub_user="$DOCKER_USER" \
      -e app_name=edgeapp \


    ansible-playbook \
      -i "$HOST_FILE" \
      --private-key "$SSH_KEY_FILE" \
      playbooks/run.yml \
      -e dockerhub_user="$DOCKER_USER" \
      -e app_name=edgeapp \

fi

echo "✅ Playbooks completed"
