```text
Challenges We Faced in EdgePaaS

Managing Environment Variables
Problem: Variables were scattered across extra-vars, GitHub environment, and env files, causing scripts to fail with “undefined variable” errors.
Solution: Collected all required variables in one place in Ansible, checked they existed, and stored them as facts. Created a canonical .env file for all scripts.
Outcome: No more missing variables. Everything can access what it needs reliably.

Getting Variables to Work Inside Docker
Problem: Even when set, some variables did not propagate into Docker containers correctly, causing startup scripts and alerts to fail.
Solution: Entrypoint sources a temporary file with all DB and environment info. Python scripts read variables from os.environ, and imports were adjusted so sibling modules could find each other.
Outcome: Variables propagate correctly, and containers behave consistently.

Docker Filling Up Small EC2 Disks
Problem: Small instances (t3.micro, t3.small) have tiny root volumes, causing Docker to fill the disk, fail containers, or destabilize the server.
Solution: Added a dedicated EBS block volume for Docker, formatted and mounted automatically, and restarted Docker safely. Added a sentinel file to run setup only once.
Outcome: Docker has dedicated space, and containers run reliably on small instances.

Tracking Builds & Controlling Cache
problem: During testing, we needed to ensure each build was fresh, but sometimes we also wanted to reuse cached layers for faster deployment.
Fix: Introduced BUILD_VERSION (using commit SHA) to tag every Docker image uniquely. For testing, we always build with --no-cache, while for production or repeated runs we optionally use cached layers to speed up builds.
Outcome: Reliable testing with fresh builds, plus faster deployments when cache can be reused.

GitHub Masking BUILD_VERSION
Problem: When using short Git commit SHA (e.g., GITHUB_SHA::6) or dynamic date strings for BUILD_VERSION, GitHub Actions automatically masked the value in outputs, treating it as a secret. This prevented downstream jobs from accessing it, causing Docker tags and deploy scripts to fail.
Solution: I decided to try BUILD_VERSION before using any secrets inside the job. Used a simple random 6-character hex string for “no-cache” builds, or “latest” for cached builds. Write it to both:
  - $GITHUB_ENV → accessible to later steps in the same job
  - $GITHUB_OUTPUT → accessible to downstream jobs via needs.build.outputs.build_version
Ensured Docker login and pushes happen only after BUILD_VERSION is safely generated.
Outcome: Downstream jobs now receive BUILD_VERSION correctly. Docker images are tagged consistently, and masking warnings are avoided.


SQLite Fallback vs Alembic Migrations
Problem: Alembic migrations are Postgres-specific and fail when SQLite fallback is active, triggering false alerts.
Solution: Skip Alembic checks when FINAL_DB_MODE=sqlite_only. Adjust health checks to report DB as ready.
Outcome: App bootstraps safely without false alarms.

Blue/Green Deployment and Container Promotion
Problem: Ensuring zero downtime when switching containers while validating new container health before removing the old one.
Solution: Built deterministic workflow using Ansible, Docker, FastAPI health endpoints, and proper Nginx port routing.
Outcome: Safe container promotion with minimal downtime risk.

Differences Across Platforms and OS
Problem: Scripts behave differently on EC2, local dev machines, and CI/CD runners due to OS, metrics, or DB variations.
Solution: Made scripts OS-aware, added universal pre-flight checks, and ensured CI/CD safety across all platforms.
Outcome: Pipeline behaves predictably everywhere.

Postgres Connectivity Problems
Problem: Conflicts between local Postgres and Render-managed Postgres caused SSL and library issues.
Solution: Removed local Postgres, kept client only, enforced SSL in the connection string. Python scripts now check connectivity only.
Outcome: Reliable Postgres connections without conflicts or unnecessary dependencies.

SQLite Fallback for Bootstrapping
Problem: Fallback paths were incorrect and environment variables were not integrated.
Solution: Added dedicated fallback file and clear environment variable, ensuring safe SQLite-only switch if Postgres is unavailable.
Outcome: App bootstraps safely in offline/fallback mode.

Alembic Migration Reliability
Problem: Shell-based migration resets depended on local binaries, prone to failure inside Docker.
Solution: Rewrote migration resets in Python with prechecks and automatic retries in the entrypoint.
Outcome: Migrations run reliably inside Docker without host dependency.

Deploying Across Dev and Prod
Problem: Running the app locally vs EC2 caused subtle failures (ports, logs, DB access, OS differences).
Solution: Entrypoint detects local vs production and adjusts behavior. Environment-specific logic lives in .env or .env.test.
Outcome: One Docker image works across environments with minimal manual changes.

Getting EC2 IP for Inventory
Problem: GitHub Actions masks secrets like EC2_IP, breaking dynamic inventory creation.
Solution: Fetch EC2 IP dynamically via AWS CLI in the workflow.
Outcome: Inventory creation works reliably, and deployments remain automated.

Installing Docker on CentOS / AWS AMI
Problem: Default OS repositories lacked the correct Docker version.
Solution: Explicitly added Docker CE repository via Ansible and verified installation.
Outcome: Docker installs consistently across all EC2 instances.
```
