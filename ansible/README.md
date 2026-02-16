# ============================================================
#  ANSIBLE LAYER — EDGEPAAS
# ============================================================

# ------------------------------------------------------------
#  PURPOSE
# ------------------------------------------------------------
- This directory defines the configuration, deployment, and orchestration layer of EdgePaaS.
- It takes a ready infrastructure and built application image, then:
  - Prepares hosts
  - Installs and configures required services
  - Deploys the application using blue/green strategy
  - Performs health checks
  - Finalizes traffic switching and cleanup
- This layer is actally where our running customized platform is built.

# ------------------------------------------------------------
#  WHY ANSIBLE IN EDGEPAAS
# ------------------------------------------------------------
- EdgePaaS separates responsibilities:
  - Terraform (`iac/`) provisions infrastructure
  - Docker (`docker/`) defines runtime behavior
  - Ansible (`ansible/`) configures hosts and executes deployments
- Ansible excels at:
  - Declarative host configuration
  - Idempotent execution
  - Clear task ordering
  - Remote orchestration without agents
- Deployments are predictable, auditable, and repeatable.

# ------------------------------------------------------------
#  RESPONSIBILITIES
# ------------------------------------------------------------
- Validate required environment variables
- Prepare EC2 hosts (users, packages, directories)
- Install and configure Docker and Nginx
- Deploy Docker containers using blue/green strategy
- Perform health and readiness checks
- Switch traffic safely
- Roll forward or fail hard with alerts
- Assumes:
  - Infrastructure already exists
  - Docker images are already built and pushed
  - Secrets injected via environment variables or CI/CD

# ------------------------------------------------------------
#  DEPLOYMENT PHILOSOPHY
# ------------------------------------------------------------
- Blue/Green deployment model:
  - One container is always assumed ACTIVE
  - One container is INACTIVE
  - Only the inactive slot is deployed
  - Traffic switches only after health checks pass
  - Previous version removed only after success
- Failures are:
  - Detected early
  - Logged explicitly
  - Alerted immediately
  - Stopped before traffic is switched

# ------------------------------------------------------------
#  EXECUTION FLOW (HIGH LEVEL)
# ------------------------------------------------------------
- Entry orchestration playbook: `run.yml`
- Execution order:
  1. Preparation phase
     - Environment validation
     - Host setup: OS, users, base services
     - Database client setup
     - Nginx installation
  2. Docker phase
     - Docker installation
     - Docker daemon configuration
     - Disk and filesystem preparation
  3. Deployment phase
     - Resolve active/inactive slots
     - Pull application images
     - Stop inactive containers
     - Start new container
     - Perform health checks
     - Switch Nginx traffic
  4. Post-deployment checks
     - Port checks
     - HTTP checks
     - Health endpoint validation
     - Final success/failure alert
     - Cleanup old containers
     - Updte active state for next deploy

# ------------------------------------------------------------
#  ENVIRONMENT AWARENESS
# ------------------------------------------------------------
- CI/CD aware:
  - Local execution
  - SSH-based remote execution
  - GitHub Actions pipelines
- Host resolution, inventory handling, and variable sourcing adapt automatically.

# ------------------------------------------------------------
#  DESIGN PRINCIPLES
# ------------------------------------------------------------
- Explicit failures over silent success
- No hidden defaults
- No manual color or slot control
- Idempotent where possible
- Clear logging and debug output
- One responsibility per playbook
- Pipeline fails loudly and early on errors

# ------------------------------------------------------------
#  SCOPE OF DIRECTORY
# ------------------------------------------------------------
- Entry orchestration playbooks
- Host preparation logic
- Docker installation logic
- Deployment pipeline logic
- Health check and alerting logic
- Templates and static files used during deployment
- Detailed descriptions documented in `docs/ansible-files.md`

