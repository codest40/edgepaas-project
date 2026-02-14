# EdgePaaS Project

```
## Overview
EdgePaaS is a **DevOps / Platform Engineering project** that provisions infrastructure, builds and runs an application, and deploys it in a repeatable, auditable, and automation‑first way.

It is designed as an internal platform deployment framework with a focus on clarity, simplicity, automation and smooth repeatability. Its purpose is to automate the full lifecycle of infrastructure provisioning, application build, deployment, and traffic management with minimal human intervention while ensuring high reliability.

Why it is built this way:

Clarity, Stability, and Automated – The project emphasizes reproducible deployments with clear, auditable workflows, reducing human errors and maintaining operational security.

Custom Configuration with Ansible – Ansible allows fine-grained control over EC2 hosts, container environments, and Nginx routing, ensuring the app and infrastructure are always in sync.

Automated, Self-Healing Platform – Once all required inputs (environment variables, secrets, etc.) are provided, the platform can fully deploy itself from a developer’s local machine to the cloud without additional manual steps.

Blue-Green Deployment Strategy – Minimizes downtime and deployment risk by routing traffic safely between active and standby containers.

CI/CD–Friendly Workflow – Designed to run in GitHub Actions or similar pipelines, supporting ephemeral environments, automated pre-flight checks, and dynamic inventories.

Observability & Debuggability – With automated notifications, logs, and post-deployment health checks, the platform provides insight into every stage of the pipeline.


EdgePaaS Workflow Summary

Infrastructure Provisioning (Terraform)
The workflow begins with Terraform, which provisions and manages all required cloud resources (EC2 instances, networking, security groups, etc.) and exposes necessary outputs like instance IDs, IP addresses, and configuration values.

Dynamic Inventory Generation (Ansible)
EC2 public IPs are dynamically fetched from the cloud and used to generate a temporary Ansible inventory. This ensures CI/CD–friendly deployments and allows ephemeral environments without persistent inventory management.

Environment Variable Normalization
All required environment variables—from GitHub Secrets, shell exports, or Ansible --extra-vars—are asserted, normalized, and promoted to host variables, making them consistently accessible across playbooks and roles.

Pre-Deployment Checks
Pre-flight checks verify host connectivity, system readiness, and container/service health before any deployment occurs, reducing deployment risk and enabling safe automation.

Application Build & Docker Push
The application is containerized and pushed to a registry as Docker images. Both blue and green versions of the container are built for zero-downtime deployments.

Blue-Green Deployment (Ansible + Nginx)
- Nginx listens on host port 80 and acts as a traffic router.
- Ansible determines the active color (blue or green) and updates Nginx to route traffic accordingly.
- Host ports (8080/8081) are mapped to container ports (80), allowing seamless blue-green switching.
- The inactive container remains ready for rollback if necessary.

Post-Deployment Health Checks
Once deployed, health checks validate that the new container is running correctly and that traffic routing is stable.

Automation, Safety, and Observability
The workflow is fully GitHub Actions–compatible, reproducible, and emphasizes automation, operational safety, and debuggability. Notifications and pipeline status reports ensure visibility at every stage.
```

```
## Repository structure

Each major folder in this repository is **self-documented**. Every top-level component (`iac/`, `ansible/`, `docker/`, `scripts/`, `.github/workflows/`) contains its own `README.md` that explains:
