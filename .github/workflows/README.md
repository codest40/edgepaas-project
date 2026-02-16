# ============================================================
#  EDGEPaaS — GITHUB ACTIONS WORKFLOWS
# ============================================================

# ------------------------------------------------------------
#  OVERVIEW
# ------------------------------------------------------------

EdgePaaS GitHub Actions workflows orchestrate:

- Infrastructure provisioning
- Application build
- Deployment
- Pipeline reporting

Key Principles:

- Infrastructure first, application second
- Immutable builds
- Blue/green deployment enforcement
- OIDC-based AWS access (no static keys)
- Reproducible from GitHub Actions
- Failures are explicit and reported

These workflows are pipeline orchestrators.

# ============================================================
#  WORKFLOW FILES
# ============================================================

.github/workflows/
├─ edgepaas.yml       # Full production pipeline
├─ cached_version.yml # Optional build optimization & experimentation
├─ test.yml           # Experimental / validation pipeline
└─ README.md          # Directory marker / placeholder

# ------------------------------------------------------------
#  edgepaas.yml — PRODUCTION PIPELINE
# ------------------------------------------------------------

Purpose:

- Single source of truth for production deployments
- Provision infra, build Docker images, deploy app via Ansible
- Generate final success/failure reports

Trigger:

- workflow_dispatch
  - input: tf_action (apply / destroy)
  - default: apply

Effect:

- apply → provision + deploy
- destroy → controlled teardown
- Ensures Terraform authority before any deployment occurs

Global Environment:

- Terraform configuration (version, directory, variables)
- Docker metadata (user, app name, tags)
- AWS region and role (OIDC)
- Feature flags (cache control)
- Propagates safely across all jobs

# ------------------------------------------------------------
#  JOBS
# ------------------------------------------------------------

Job: terraform

- Role: Infrastructure authority
- Responsibilities:
  - AWS OIDC authentication
  - Terraform init, fmt, validate
  - Plan & apply/destroy infra
- Guarantees:
  - Blocks build/deploy if Terraform fails
  - Ensures state consistency
  - Destroy halts downstream jobs

Job: build

- Role: Immutable application packaging
- Runs only after Terraform success (not destroy)
- Responsibilities:
  - Docker Hub authentication
  - Build blue & green images
  - Push versioned images (commit SHA)
- Design Choices:
  - Pre-build both blue & green
  - No image mutation on server
  - Avoid "latest" tag in production
- Guarantees:
  - Repeatable rollbacks
  - CI/CD-safe artifact generation

Job: deploy

- Role: Controlled application rollout
- Responsibilities:
  - Discover EC2 instances dynamically
  - Secure SSH access
  - Generate runtime inventory
  - Run Ansible orchestration (run.yml)
  - Inject runtime secrets safely
  - Enforce blue/green switching
- Key Characteristics:
  - Inventory generated dynamically
  - Secrets never stored in repo
  - Ansible is deployment authority
  - GitHub Actions does not deploy directly

Job: final_report

- Role: Observability & outcome reporting
- Responsibilities:
  - Collect job-level results
  - Compute overall pipeline status
  - Generate concise summary
  - Send email notifications
- Guarantees:
  - Failures are not silent
  - Provides full visibility of deployment

# ------------------------------------------------------------
#  test.yml — EXPERIMENTAL PIPELINE
# ------------------------------------------------------------

Purpose:

- Test workflow logic
- Validate Docker builds
- Verify Ansible changes
- Debug safely without touching infra

Key Differences from edgepaas.yml:

- No Terraform stage
- Faster iteration
- Safe sandbox for testing
- Mirrors production pipeline where possible

# ------------------------------------------------------------
#  EXECUTION FLOW SUMMARY
# ------------------------------------------------------------

workflow_dispatch
        ↓
Terraform (OIDC + IaC)
        ↓
Docker Build (blue & green)
        ↓
Ansible Deploy (blue/green switch)
        ↓
Final Report (email + status)

# ------------------------------------------------------------
#  GUARANTEES
# ------------------------------------------------------------

- Deployment requires known-good infrastructure
- No traffic switch without health checks
- Immutable builds ensure repeatable deployments
- Failures are explicit, not silent
- No static AWS credentials required
- No manual mutation of production hosts
