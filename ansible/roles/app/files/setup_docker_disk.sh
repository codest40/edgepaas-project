#!/bin/bash
# One-time Docker EBS + cgroup v2 setup (Amazon Linux 2023)

set -euo pipefail

DEVICE="/dev/nvme1n1"
MOUNT="/var/lib/docker"
LABEL="docker-data"
SENTINEL="/etc/docker/.docker-ebs-initialized"

echo "Checking Docker EBS initialization state..."

if [[ -f "$SENTINEL" ]]; then
  echo "✅ Docker EBS already initialized — skipping"
  exit 0
fi

echo "Initializing Docker on dedicated EBS volume"

# Ensure device exists
if [[ ! -b "$DEVICE" ]]; then
  echo "❌ Block device $DEVICE not found"
  exit 1
fi

# Stop Docker before touching storage
echo "Stopping Docker"
systemctl stop docker || true

# Create filesystem ONLY if none exists
if ! blkid "$DEVICE" >/dev/null 2>&1; then
  echo "Creating XFS filesystem on $DEVICE"
  mkfs.xfs "$DEVICE"
else
  echo "Filesystem already exists on $DEVICE"
fi

# Ensure mount point exists
mkdir -p "$MOUNT"

# Label filesystem (safe to re-run)
echo "Setting filesystem label: $LABEL"
xfs_admin -L "$LABEL" "$DEVICE" || true

# Persist mount in fstab if not already present
if ! grep -q "LABEL=$LABEL" /etc/fstab; then
  echo "Persisting mount in /etc/fstab"
  echo "LABEL=$LABEL $MOUNT xfs defaults,nofail 0 2" >> /etc/fstab
else
  echo "fstab entry already present"
fi

# Mount volumes
echo "Mounting volumes"
mount -a

# Docker daemon config (CRITICAL for AL2023 + cgroup v2)
echo "Configuring Docker to use systemd cgroup driver"
mkdir -p /etc/docker
cat >/etc/docker/daemon.json <<'EOF'
{
  "exec-opts": ["native.cgroupdriver=systemd"]
}
EOF

# Enable Docker to start on boot
systemctl enable docker

# Mark initialization complete BEFORE restart/reboot
mkdir -p "$(dirname "$SENTINEL")"
touch "$SENTINEL"

# Reload systemd & start Docker
echo "Restarting Docker"
systemctl daemon-reexec
systemctl start docker

echo "✅ Docker EBS + cgroup setup complete"
exit 0
