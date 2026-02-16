# ============================================================
#  ANSIBLE FILES REFERENCE — EDGEPAAS
# ============================================================

# ------------------------------------------------------------
#  OVERVIEW
# ------------------------------------------------------------
- This document describes each file and directory inside the `ansible/` layer.
- Explains what each component does, when it runs, and how it fits into the deployment pipeline.
- This is the operational contract of the Ansible layer.

# ------------------------------------------------------------
#  ENTRY & ORCHESTRATION
# ------------------------------------------------------------

## run.yml
- Role: Primary orchestration entrypoint
- This is the ONLY playbook that should be executed directly.

Responsibilities:
- Define execution order
- Import all other playbooks
- Ensure correct sequencing and failure propagation

Execution Flow:
- Preparation
- Docker installation & setup
- Application deployment
- Post-deployment validation

All other playbooks are called from here.
Never manually chain playbooks.

# ------------------------------------------------------------
#  PREPARATION PHASE
# ------------------------------------------------------------

## prep.yml
- Role: Host readiness & environment validation
- Prepares the target host before any deployment logic runs.

Responsibilities:
- Validate required variables
- Ensure required packages are installed
- Prepare directories and permissions
- Configure OS-level dependencies
- Install and configure base Nginx

Guarantee:
- Host is deployment-ready before proceeding.
- Failures here stop the pipeline immediately.

# ------------------------------------------------------------
#  DOCKER PHASE
# ------------------------------------------------------------

## docker.yml
- Role: Docker runtime setup
- Handles everything required to safely run containers on the host.

Responsibilities:
- Install Docker engine
- Configure Docker daemon
- Ensure Docker is running and enabled
- Prepare disk and filesystem layout
- Validate Docker usability

Guarantee:
- Idempotent and safe to re-run.

# ------------------------------------------------------------
#  DEPLOYMENT PHASE
# ------------------------------------------------------------

## deploy.yml
- Role: Application deployment & traffic switching
- Core deployment engine of EdgePaaS.

Responsibilities:
- Determine active and inactive deployment slots
- Pull application image
- Stop inactive container
- Start new container in inactive slot
- Perform container-level health checks
- Switch Nginx traffic
- Persist deployment state

Blue/Green Rules:
- No traffic switch without passing health checks
- No cleanup before success
- No implicit rollback

# ------------------------------------------------------------
#  VALIDATION & FINALIZATION
# ------------------------------------------------------------

## checks.yml
- Role: Post-deployment verification and cleanup
- Runs after traffic has been switched.

Responsibilities:
- Port reachability checks
- HTTP endpoint validation
- Application health verification
- Success or failure signaling
- Cleanup old containers and resources

Guarantee:
- Final gate before declaring deployment success.

# ------------------------------------------------------------
#  CONFIGURATION FILES
# ------------------------------------------------------------

## ansible.cfg
- Role: Ansible execution behavior
- Controls runtime behavior including:
  - SSH settings
  - Privilege escalation
  - Output formatting
  - Timeout handling

Ensures consistent behavior across:
- Local runs
- CI/CD pipelines
- Remote executions

## local.ini
- Role: Local development inventory
- Used for:
  - Testing playbooks locally
  - Debugging without CI
  - Dry-running logic safely

Never used in production pipelines.

# ------------------------------------------------------------
#  SUPPORTING DIRECTORIES
# ------------------------------------------------------------

## files/
- Role: Static assets
- Contains files copied directly to target hosts:
  - Shell scripts
  - Configuration fragments
  - SQL or data files
- Files are NOT templated.

## templates/
- Role: Jinja2 templates
- Contains dynamically rendered configuration files:
  - Nginx configs
  - Service definitions
  - Runtime configuration files
- Rendered using Ansible variables at execution time.

# ------------------------------------------------------------
#  EXECUTION GUARANTEES
# ------------------------------------------------------------
- Deterministic execution order
- Explicit failure points
- No hidden side effects
- Environment-aware behavior
- Safe re-runs where applicable

If a deployment succeeds:
- It is provably healthy.

If it fails:
- It fails loudly and early.

# ------------------------------------------------------------
#  SUMMARY
# ------------------------------------------------------------
Component        Responsibility
run.yml          Orchestration entrypoint
prep.yml         Host & environment preparation
docker.yml       Docker runtime setup
deploy.yml       Blue/green deployment logic
checks.yml       Validation & cleanup
ansible.cfg      Execution behavior
local.ini        Local testing
files/           Static assets
templates/       Dynamic configs
