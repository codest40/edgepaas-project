#!/bin/bash
set -euo pipefail

DEVICE="/dev/nvme1n1"
MOUNT="/var/lib/docker"
LABEL="docker-data"
SENTINEL="$MOUNT/.docker-ebs-initialized"

# Exit early if already initialized
if [[ -f "$SENTINEL" ]]; then
  echo "Docker EBS already initialized"
  exit 0
fi

# Stop Docker safely if running
systemctl stop docker || true

# Format device if it has no filesystem
if ! blkid "$DEVICE" >/dev/null 2>&1; then
  mkfs.xfs "$DEVICE"
fi

# Ensure mount directory exists
mkdir -p "$MOUNT"

# Label device (ignore errors if already labeled)
xfs_admin -L "$LABEL" "$DEVICE" || true

# Add to fstab if not already present
if ! grep -q "LABEL=$LABEL" /etc/fstab; then
  echo "LABEL=$LABEL $MOUNT xfs defaults,nofail 0 2" >> /etc/fstab
fi

# Mount the volume
mount -a

# Verify mount
mountpoint -q "$MOUNT" || {
  echo "Mount failed"
  exit 1
}

# Start Docker
systemctl enable docker
systemctl start docker

# Wait for Docker daemon to be fully ready
echo "Waiting for Docker daemon to be ready..."
for i in {1..20}; do
  if docker info >/dev/null 2>&1; then
    echo "Docker daemon is ready!"
    break
  fi
  echo "Docker not ready yet... retrying ($i/20)"
  sleep 3
done

# Mark initialization complete
touch "$SENTINEL"
echo "Docker disk setup completed successfully"
