# ============================================================
#  EDGEPaaS — INTERNAL PLATFORM DEPLOYMENT FRAMEWORK
# ============================================================

# ------------------------------------------------------------
#  OVERVIEW
# ------------------------------------------------------------

EdgePaaS is a DevOps / Platform Engineering project that:

- Provisions infrastructure
- Builds and runs an application
- Deploys using automation-first principles
- Ensures repeatability and auditability

It is designed as an internal platform deployment framework.

Primary goals:

- Clarity
- Simplicity
- Automation
- Safe repeatability

The platform automates the full lifecycle:

- Infrastructure provisioning
- Application build
- Deployment
- Traffic management

Minimal human intervention.
High operational reliability.


# ------------------------------------------------------------
#  ARCHITECTURAL PHILOSOPHY
# ------------------------------------------------------------

Clarity, Stability, Automation

- Reproducible deployments
- Clear and auditable workflows
- Reduced human error
- Operational security by default


Custom Configuration with Ansible

- Fine-grained EC2 host control
- Deterministic container configuration
- Nginx traffic routing management
- Infrastructure and application always in sync


Self-Deploying Platform Model

Once required inputs are provided:

- Environment variables
- Secrets
- Registry credentials

The platform can fully deploy itself:

Local machine → Cloud → Live traffic

No manual SSH.
No manual server edits.
No manual traffic switching.


Blue-Green Deployment Strategy

- Two container versions (blue / green)
- Safe traffic switching
- Instant rollback capability
- Minimal downtime


CI/CD-First Design

- GitHub Actions compatible
- Ephemeral environment support
- Automated pre-flight checks
- Dynamic inventory generation
- Zero persistent server state assumptions


Observability & Debuggability

- Pre-flight validation
- Structured logs
- Health checks
- Deployment status visibility
- Post-deployment verification


# ============================================================
#  WORKFLOW SUMMARY
# ============================================================

# ------------------------------------------------------------
#  1. INFRASTRUCTURE PROVISIONING (TERRAFORM)
# ------------------------------------------------------------

Terraform provisions:

- EC2 instances
- Networking components
- Security groups
- Supporting cloud resources

Outputs exposed:

- Instance IDs
- Public IP addresses
- Required configuration values

Infrastructure is:

- Version-controlled
- Idempotent
- State-managed
- Reproducible


# ------------------------------------------------------------
#  2. DYNAMIC INVENTORY GENERATION (ANSIBLE)
# ------------------------------------------------------------

- EC2 public IPs fetched dynamically
- Temporary inventory generated at runtime
- No static inventory files required

Enables:

- CI/CD-friendly deployments
- Ephemeral environments
- Clean teardown and recreation cycles


# ------------------------------------------------------------
#  3. ENVIRONMENT VARIABLE NORMALIZATION
# ------------------------------------------------------------

Inputs may come from:

- GitHub Secrets
- Shell environment
- Ansible --extra-vars

All variables are:

- Asserted
- Normalized
- Promoted to host variables

Ensures:

- Consistency across roles
- Deterministic configuration
- No hidden variable drift


# ------------------------------------------------------------
#  4. PRE-DEPLOYMENT CHECKS
# ------------------------------------------------------------

Before deployment begins:

- Host connectivity verified
- System readiness validated
- Required services checked
- Container health pre-validated

Purpose:

- Reduce deployment risk
- Enable safe automation
- Prevent partial rollouts


# ------------------------------------------------------------
#  5. APPLICATION BUILD & DOCKER PUSH
# ------------------------------------------------------------

- Application containerized
- Docker image built
- Image pushed to registry

Two versions prepared:

- Blue
- Green

Supports zero-downtime deployment model.


# ------------------------------------------------------------
#  6. BLUE-GREEN DEPLOYMENT (ANSIBLE + NGINX)
# ------------------------------------------------------------

Traffic Model:

- Nginx listens on host port 80
- Containers run on internal ports
- Host ports 8080 / 8081 map to container port 80

Deployment Logic:

- Determine active color
- Deploy inactive color
- Update Nginx routing
- Reload safely

Inactive container remains available for rollback.


# ------------------------------------------------------------
#  7. POST-DEPLOYMENT HEALTH CHECKS
# ------------------------------------------------------------

After routing switch:

- Container health verified
- HTTP response validated
- Traffic stability confirmed

Ensures:

- No silent failures
- No broken traffic routes


# ------------------------------------------------------------
#  AUTOMATION, SAFETY & VISIBILITY
# ------------------------------------------------------------

The entire workflow is:

- GitHub Actions compatible
- Fully reproducible
- CI-safe
- Idempotent
- Observable

Pipeline outputs include:

- Deployment status
- Health validation results
- Execution logs
- Failure visibility

No hidden steps.
No manual patching.
No untracked configuration drift.


# ============================================================
#  PLATFORM ENGINEERING PRINCIPLE
# ============================================================

EdgePaaS is not only a deployment project.

It is a controlled, automation-first platform that:

- Encodes operational knowledge into code
- Eliminates manual infrastructure handling
- Provides safe release mechanisms
- Treats infrastructure as a product

Infrastructure.
Deployment.
Traffic.
Validation.

All codified.
All repeatable.
All observable.

```
## Repository structure

Each major folder in this repository is self-documented. 
Every top-level component (`iac/`, `ansible/`, `docker/`, `scripts/`, `.github/workflows/`) contains its own `README.md` that explains in detail.


