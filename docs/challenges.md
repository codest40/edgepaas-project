# ============================================================
#  EDGEPAAS — ENGINEERING CHALLENGES & SOLUTIONS
# ============================================================

This document summarizes the key engineering challenges encountered
while building EdgePaaS, including root causes, applied solutions,
and architectural outcomes.

It captures the evolution of the platform into a stable,
production-ready system.


# ============================================================
#  ENVIRONMENT VARIABLES MANAGEMENT
# ============================================================

Problem:
- Variables were scattered across:
  - Ansible extra-vars
  - GitHub environments
  - .env files
- Resulted in "undefined variable" errors.
- Scripts failed unpredictably.

Solution:
- Centralized all required variables inside Ansible.
- Validated existence early in execution.
- Stored validated values as Ansible facts.
- Generated a canonical `.env` file consumed by all scripts.

Outcome:
- No more missing variable errors.
- Deterministic environment propagation.
- All layers access the same source of truth.


# ============================================================
#  VARIABLE PROPAGATION INTO DOCKER
# ============================================================

Problem:
- Some environment variables did not reach Docker containers.
- Startup scripts and alerting logic failed.
- Python modules had import resolution issues.

Solution:
- Entrypoint sources a temporary file containing DB and runtime info.
- Python scripts read from `os.environ`.
- Adjusted module imports for correct sibling resolution.

Outcome:
- Variables propagate correctly into containers.
- Startup scripts behave consistently.
- Alerts function reliably.


# ============================================================
#  DOCKER DISK EXHAUSTION ON SMALL EC2 INSTANCES
# ============================================================

Problem:
- Small EC2 instances (t3.micro, t3.small) have tiny root volumes.
- Docker filled root disk.
- Containers failed or host became unstable.

Solution:
- Provisioned dedicated EBS volume for Docker.
- Automatically formatted and mounted via Ansible.
- Restarted Docker safely.
- Added sentinel file to ensure setup runs only once.

Outcome:
- Docker has dedicated storage.
- Containers run reliably on small instances.
- Host stability preserved.


# ============================================================
#  BUILD VERSIONING & CACHE CONTROL
# ============================================================

Problem:
- Needed fresh builds during testing.
- Also needed cache reuse for faster production deploys.

Solution:
- Introduced BUILD_VERSION using commit SHA or random hex.
- Tagged each Docker image uniquely.
- Testing builds use `--no-cache`.
- Production builds optionally reuse cache.

Outcome:
- Reliable fresh builds during testing.
- Faster deployments when cache is reused.
- Clear traceability of image versions.


# ============================================================
#  GITHUB MASKING BUILD_VERSION
# ============================================================

Problem:
- Short commit SHA or dynamic strings were auto-masked.
- GitHub treated them as secrets.
- Downstream jobs failed to receive BUILD_VERSION.

Solution:
- Generated BUILD_VERSION before defining any secrets so runner thinks they are not secrets.
- Used:
  - Short random 6-character SHA for no-cache builds 
  - "latest" for cached builds
- Write to:
  - $GITHUB_ENV (same job steps)
  - $GITHUB_OUTPUT (downstream jobs)
- Perform Docker login only after BUILD_VERSION is generated.

Outcome:
- Downstream jobs receive BUILD_VERSION correctly.
- No masking warnings.
- Consistent Docker tagging.


# ============================================================
#  SQLITE FALLBACK VS ALEMBIC MIGRATIONS
# ============================================================

Problem:
- Alembic is PostgreSQL-specific.
- SQLite fallback triggered false migration failures.
- Health checks produced false alerts.

Solution:
- Skip Alembic checks when FINAL_DB_MODE=sqlite_only.
- Adjust readiness logic to reflect active DB mode.

Outcome:
- Safe SQLite fallback.
- No false alarms.
- Accurate health reporting.


# ============================================================
#  BLUE/GREEN DEPLOYMENT & CONTAINER PROMOTION
# ============================================================

Problem:
- Needed zero downtime.
- Must validate new container before switching traffic.
- Avoid removing healthy container prematurely.

Solution:
- Deterministic Ansible workflow.
- Docker slot switching.
- FastAPI health endpoints used as gate.
- Controlled Nginx port routing.

Outcome:
- Safe container promotion.
- Minimal downtime risk.
- Deterministic traffic switching.


# ============================================================
#  CROSS-PLATFORM DIFFERENCES
# ============================================================

Problem:
- Scripts behaved differently across:
  - EC2
  - Local development
  - CI/CD runners
- Differences in OS, metrics, DB access.

Solution:
- OS-aware scripts.
- Universal pre-flight checks.
- CI/CD-safe logic across platforms.

Outcome:
- Predictable behavior everywhere.
- Reduced environment-specific bugs.


# ============================================================
#  POSTGRES CONNECTIVITY CONFLICTS
# ============================================================

Problem:
- Local Postgres conflicted with managed Postgres.
- SSL and driver issues.
- Library mismatches.

Solution:
- Removed local Postgres server.
- Kept client libraries only.
- Enforced SSL in connection string.
- Scripts now validate connectivity only.

Outcome:
- Reliable Postgres connections.
- No environment conflicts.
- Clean dependency boundaries.


# ============================================================
#  SQLITE FALLBACK FOR BOOTSTRAPPING
# ============================================================

Problem:
- Incorrect fallback paths.
- Environment variables not integrated properly.

Solution:
- Dedicated fallback DB file.
- Clear FINAL_DB_MODE environment variable.
- Safe SQLite-only activation when Postgres unavailable.

Outcome:
- App always boots.
- Offline/fallback mode is deterministic.
- No silent DB ambiguity.


# ============================================================
#  ALEMBIC MIGRATION RELIABILITY
# ============================================================

Problem:
- Shell-based migration resets depended on host binaries.
- Failed inside Docker.

Solution:
- Rewrote migration resets in Python.
- Added prechecks and automatic retries.
- Integrated into entrypoint logic.

Outcome:
- Migrations run reliably inside Docker.
- No host-level dependency.
- Deterministic schema management.


# ============================================================
#  DEV VS PROD DEPLOYMENT DIFFERENCES
# ============================================================

Problem:
- Local vs EC2 differences:
  - Ports
  - Logs
  - DB access
  - OS behavior

Solution:
- Entrypoint detects environment.
- Adjusts behavior accordingly.
- Environment-specific logic placed in:
  - .env
  - .env.test

Outcome:
- Single Docker image works everywhere.
- Minimal manual adjustments.
- Predictable runtime behavior.


# ============================================================
#  EC2 INVENTORY IP MASKING
# ============================================================

Problem:
- GitHub masked EC2_IP as secret.
- Dynamic Ansible inventory creation failed.

Solution:
- Fetch EC2 IP dynamically via AWS CLI.
- Avoid relying on masked values.

Outcome:
- Reliable dynamic inventory generation.
- Fully automated deployments.


# ============================================================
#  DOCKER INSTALLATION ON CENTOS / AWS AMI
# ============================================================

Problem:
- Default repositories lacked correct Docker version.
- Installation inconsistent.

Solution:
- Explicitly added Docker CE repository via Ansible.
- Verified installation steps.

Outcome:
- Consistent Docker installation.
- Reliable EC2 provisioning.
- Reproducible infrastructure setup.


