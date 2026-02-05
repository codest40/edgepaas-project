# Workflow Overview

Step 1 — CI/CD (GitHub Actions)

Trigger: Push to main branch

Jobs:

Build Docker images

Push to Docker registry

Trigger Ansible deployment playbook via SSH (or API)

Step 2 — Ansible runtime deployment

Common role: Prepare EC2 host (install Docker, users, updates)

Docker role: Pull new image, stop old containers, start new containers

App role: Blue-green orchestration

Maintain two container sets (blue and green)

Update Nginx routing dynamically

Health-check new containers before switching traffic

Step 3 — Post-deploy

Rollback if health checks fail

Optionally clean old containers/images

Outputs can be recorded in Terraform outputs for monitoring
