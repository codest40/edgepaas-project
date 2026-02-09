# EdgePaaS Ansible Workflow — Interview Summary

## Project Context

**EdgePaaS** is a DevOps / Platform Engineering project that deploys a **Python-based application** packaged in **Docker containers** onto **AWS EC2 instances**.

The Ansible workflow is designed to ensure:

- Fully automated deployments
- Reproducibility across environments
- Strong pre-deployment validation
- Safe runtime configuration
- Health-aware rollout and verification

This setup is **CI/CD–first** and integrates tightly with **GitHub Actions**.

---

## 1️⃣ Infrastructure & Environment Preparation

### Dynamic Inventory Generation

- EC2 public IPs are fetched dynamically using the **AWS CLI**
- Instances are discovered via **EC2 tags**
- A temporary `inventory.ini` file is generated at runtime containing:
  - Host IPs
  - SSH user
  - Python interpreter path
  - SSH options

This avoids static inventories and enables **ephemeral infrastructure support**.

---

### SSH Setup

- Private SSH keys are securely injected from **GitHub Secrets**
- `StrictHostKeyChecking` is disabled to allow non-interactive automation
- SSH configuration is fully compatible with GitHub Actions runners

---

## 2️⃣ Universal Environment Variable Handling

### Purpose

Provide a **single, universal mechanism** to collect and validate all required environment variables, regardless of source.

Supported sources:
- GitHub Actions secrets
- Exported environment variables
- Ansible `--extra-vars`

---

### Checks & Promotion

- Each required variable is:
  - Asserted for existence
  - Asserted to be non-empty
- Valid variables are **promoted to host vars**
- Promoted vars are accessible throughout the playbook via: {{ VARIABLE_NAME }}


---

### Validation & Debugging

- Optional debug tasks confirm variables are loaded correctly
- Prevents runtime failures caused by missing secrets or misconfiguration

---

## 3️⃣ Pre-Deployment Checks

### Connectivity & Runtime Smoke Tests

- Basic Ansible `ping` to confirm host reachability
- HTTP health check against `/health`
- Fallback to raw `curl` if the Ansible HTTP module fails
- Failures are logged:
- Non-critical failures do **not** block deployment
- Critical failures fail fast when required

---

### Docker Readiness

- Ensures Docker is installed and running
- Confirms DockerHub credentials are available
- Validates ability to:
- Build images
- Tag images
- Prepare for blue/green deployment

---

## 4️⃣ Application Deployment

### CI/CD Integration

Fully integrated with **GitHub Actions**:

- Secrets (DB credentials, email configs, Docker credentials) injected automatically
- Environment variables promoted into Ansible host vars
- No hardcoded secrets
- No repeated secret lookups

---

### Deployment Strategy

- Supports **blue/green Docker deployments**
- Containers are deployed side-by-side
- Traffic switches via port or container promotion
- Minimizes downtime and rollback risk

---

### Ansible Tasks

- Install required system dependencies
- Run database migrations when enabled
- Deploy and start Docker containers
- Apply runtime configuration using promoted host vars

All sensitive values are sourced from validated host vars.

---

## 5️⃣ Post-Deployment & Validation

### Health Checks

- Verify container responsiveness via HTTP endpoints
- Log deployment success or failure
- Optionally trigger alerts via configured email addresses

---

### Debug & Verification Tasks

- Output selected host vars for verification
- Confirm flags such as:
- `ANSIBLE_HOST_KEY_CHECKING`
- `USE_SQLITE`
- Ensures runtime environment matches expectations

---

## 6️⃣ Key Engineering Features

- **Universal env var preparation**
- Reusable across environments and pipelines
- **GitHub Actions compatibility**
- Seamless secret propagation into Ansible
- **Strong assertions & error handling**
- Fail fast on missing critical configuration
- Log warnings for non-blocking issues
- **Blue/green deployment**
- Reduced downtime
- Safer releases
- **Extensible by design**
- New variables added via a single `required_vars` list
- Scales cleanly across environments and teams

---

## 🧠 Summary

This Ansible workflow demonstrates:

- Production-grade automation
- Clear separation of concerns
- CI/CD-native design
- Defensive validation before deployment
- Safe, observable, and repeatable infrastructure operations

It reflects **real-world DevOps and Platform Engineering practices**, not toy automation.


