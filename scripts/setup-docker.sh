#!/bin/bash
# Setup Docker on dedicated EBS volume (Amazon Linux 2023)

set -euo pipefail

DEVICE="/dev/nvme1n1"
MOUNT="/var/lib/docker"
LABEL="docker-data"

echo "▶ Stopping Docker (if running)..."
systemctl stop docker || true

# Create filesystem only if none exists
if ! blkid "$DEVICE" >/dev/null 2>&1; then
  echo "▶ Creating XFS filesystem on $DEVICE"
  mkfs.xfs "$DEVICE"
fi

# Ensure mount point exists
mkdir -p "$MOUNT"

# Label filesystem (idempotent)
xfs_admin -L "$LABEL" "$DEVICE" || true

# Persist mount
if ! grep -q "LABEL=$LABEL" /etc/fstab; then
  echo "▶ Persisting mount in /etc/fstab"
  echo "LABEL=$LABEL $MOUNT xfs defaults,nofail 0 2" >> /etc/fstab
fi

# Mount volumes
mount -a

# Docker daemon config (CRITICAL for AL2023): For cgroup version runtime crash
mkdir -p /etc/docker
cat >/etc/docker/daemon.json <<'EOF'
{
  "exec-opts": ["native.cgroupdriver=systemd"]
}
EOF

# Restart Docker cleanly
systemctl daemon-reexec
systemctl restart docker
systemctl enable docker

echo "✅ Docker storage + cgroup configuration complete"
