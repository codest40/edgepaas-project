#!/bin/bash

d=$(date)
ACTIVE_COLOR=$(cat /opt/edgepaas/ACTIVE_COLOR)
CONTAINER="{{ app_name }}-$ACTIVE_COLOR"
HEALTH=$(docker inspect --format='{{.State.Health.Status}}' $CONTAINER)
logger=$"/var/log/edgepaas/monitor.log"
mkdir -p "$logger"

if [ "$HEALTH" != "healthy" ]; then
    echo "$(date): $CONTAINER is unhealthy. Triggering Ansible recovery."
    export active_color="$ACTIVE_COLOR"
    if ansible-playbook roles/checks/tasks/main.yml; then
      echo "[$d]: Recovery successful and completed" > "$logger"
    fi
fi
