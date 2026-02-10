# EdgePaaS

EdgePaaS is a **DevOps / Platform Engineering project** that provisions infrastructure, builds and runs an application, and deploys it in a repeatable, auditable, and automation‑first way.

The goal of this repo is not just to *deploy an app*, but to demonstrate **how infrastructure, configuration, CI/CD, and runtime concerns fit together as a system**.

This project intentionally separates concerns:

* **Infrastructure provisioning** (Terraform)
* **Configuration & orchestration** (Ansible)
* **Application & runtime** (Docker)
* **Glue & automation** (scripts)

---

## High‑level workflow

1. **Provision cloud infrastructure** using Terraform
2. **Generate inventory dynamically** for configuration management
3. **Prepare hosts** (OS checks, Docker, system dependencies)
4. **Build & deploy the application** in containers
5. **Verify health & runtime readiness**

Each step is automated, repeatable, and designed to fail fast when assumptions are broken.

---

## Repository structure

Each major folder in this repository is **self-documented**. Every top-level component (`iac/`, `ansible/`, `docker/`, `scripts/`, `.github/workflows/`) contains its own `README.md` that explains:

* Why the component exists
* What problem it solves
* How it is expected to be used
* What assumptions it makes about the system

The root `README.md` gives the big picture. The folder-level READMEs go deep.

---

## Repository structure

Each major folder in this repository is **self-documented**. Every top-level component (`iac/`, `ansible/`, `docker/`, `scripts/`) contains its own `README.md` that explains:

* Why the component exists
* What problem it solves
* How it is expected to be used
* What assumptions it makes about the system

The root `README.md` gives the big picture. The folder-level READMEs go deep.

---

## Repository structure

```text
.
├── ansible/                # Configuration management & orchestration (final home for playbooks)
│   ├── ansible.cfg
│   ├── inventory/          # Static & CI inventories
│   ├── playbooks/          # Entry playbooks (setup, deploy, etc.)
│   ├── roles/              # Reusable roles (docker, app, checks, common)
│   ├── docs/               # Ansible-specific rationale & workflow
│   └── test/               # Fast tests & experiments
│
├── docker/                 # Application runtime
│   ├── Dockerfile
│   ├── app/                # Python application source
│   └── docs/               # Runtime & container behavior docs
│
├── iac/                    # Infrastructure as Code (Terraform)
│   ├── backend.tf
│   ├── provider.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── budget.tf
│   ├── boot/               # Bootstrap state backend (S3/DynamoDB)
│   └── runner.sh           # Opinionated Terraform runner
│
├── scripts/                # Helper & CI glue scripts
│   ├── update-inventory.sh
│   ├── ci_inventory.sh
│   └── find-yml.sh
│
├── docs/                   # Cross‑cutting design & workflow documentation
│   ├── structure.md
│   ├── workflow.md
│   └── route-flow.md
│
└── README.md               # You are here
```

> Note: a temporary Ansible testing folder exists during development. It will be fully merged into `ansible/` as the final structure.

---

## CI/CD automation (`.github/workflows/`)

GitHub Actions is the **control plane** for this project.

Workflows are responsible for:

* Terraform validation and provisioning
* Safe, repeatable Ansible execution
* Inventory generation for CI runs
* Environment variable injection from GitHub Secrets
* Controlled deployment triggers and testing

Each workflow is scoped, explicit, and documented in `.github/workflows/README.md`. The intent is to keep CI logic **observable and boring**, not clever.

---

## Infrastructure (Terraform – `iac/`)

Terraform is responsible for **cloud‑level concerns only**:

* Networking
* Compute
* State management
* Budgets & safety rails

Key principles:

* Remote state with locking
* Minimal magic
* Explicit variables & outputs
* Scripts exist to *wrap*, not hide, Terraform behavior

The `boot/` directory exists solely to bootstrap Terraform state (S3 + DynamoDB) before the main infrastructure runs.

---

## Configuration & orchestration (Ansible – `ansible/`)

Ansible handles **everything that happens *after* a server exists**:

* Host validation & safety checks
* Docker installation & configuration
* Environment preparation
* Application deployment
* Runtime verification

The structure follows a **role‑first approach**:

* `common` – shared primitives
* `docker` – container runtime setup
* `app` – application deployment logic
* `checks` – preflight & post‑deploy validation

Playbooks are intentionally thin; most logic lives inside roles.

---

## Application & runtime (Docker – `docker/`)

The application is a containerized Python service with:

* Explicit environment bootstrapping
* Database readiness checks
* Alembic migrations
* Multiple startup guards (`wait_for_db*`)

Docker is treated as a **runtime boundary**, not a deployment tool. Build and run behavior is deterministic and reproducible.

---

## Scripts & automation (`scripts/`)

Shell scripts exist only where they add clarity:

* Inventory generation for CI/CD
* Small discovery helpers
* Zero business logic hidden in scripts

If logic grows, it moves into Ansible or Terraform.

---

## Design philosophy

This project follows a few non‑negotiable rules:

* **Automation does not remove responsibility**
* **Fail fast > silent success**
* **Explicit is better than clever**
* **Infra, config, and app lifecycles are separate**

The repo is intentionally verbose in structure and documentation to make reasoning and debugging easier under pressure.

---

## Who this is for

* Platform / DevOps / SRE engineers
* People preparing for real‑world infra interviews
* Anyone who wants to see how Terraform, Ansible, Docker, and CI/CD fit together *as a system*

---

## Summary workflow

In the EdgePaaS workflow, infrastructure provisioning begins with **Terraform**, which creates and manages cloud resources and exposes the required outputs.

From there, **EC2 IPs are dynamically fetched** and used to generate a **disposable Ansible inventory**, making the workflow safe for CI/CD and ephemeral environments.

All required environment variables—whether sourced from **GitHub Secrets**, exported shell variables, or **Ansible `--extra-vars`**—are **asserted early**, normalized, and promoted to **host variables**, ensuring they are directly accessible across roles and playbooks.

Before any deployment occurs, **pre-flight connectivity, system, and health checks** validate host readiness.

The application is then **built and pushed as Docker images**, followed by **container deployment using blue/green strategies** to minimize downtime and risk.

Finally, **post-deployment health checks** confirm runtime correctness before traffic is considered stable.

The entire workflow is **GitHub Actions–compatible**, reproducible, and designed to prioritize automation, safety, and debuggability in production deployments.

---

## Status

This is an active, evolving project. Structures may tighten, but core principles will remain stable.

Contributions, reviews, and hard questions are welcome.

