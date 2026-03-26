```text
Scripts Layer — EdgePaaS

Purpose

The scripts/ directory contains local and CI/CD helper utilities used to glue EdgePaaS layers together.

These scripts are not core platform logic.
They exist to:

Improve developer ergonomics

Reduce repetitive CLI work

Bridge automation gaps between Terraform, Ansible, and CI/CD

Provide safe, observable execution helpers

Think of this directory as operational tooling, not infrastructure or runtime code.

Why This Layer Exists

As EdgePaaS grew, certain tasks did not belong cleanly to:

Terraform (infrastructure provisioning)

Ansible (configuration & deployment)

Docker (runtime behavior)

Examples include:

Searching and inspecting project files quickly

Dynamically updating Ansible inventory

Handling local vs CI execution differences

Placing these concerns in scripts/ keeps the core layers clean, minimal, and single-purpose.

What This Layer Handles

The scripts layer focuses on:

File discovery and inspection utilities

YAML / shell exploration helpers

Inventory generation and update logic

CI/CD-safe execution wrappers

These scripts are:

Safe to run locally

CI-aware when necessary

Explicit about failures

Designed to fail fast and loudly

Design Principles

All scripts in this directory follow the same philosophy:

No hidden side effects

Explicit inputs

Strict shell mode (set -euo pipefail)

Clear terminal feedback

No environment assumptions

If a script depends on external state (AWS CLI, env vars, SSH keys), it checks and reports clearly.

Relationship to Other Layers

The scripts/ directory may:

Read Terraform outputs

Generate or update Ansible inventory

Trigger Ansible playbooks

Assist developers during debugging

But it does not:

Provision infrastructure directly

Modify application runtime behavior

Replace CI/CD pipelines

It complements the platform — it does not control it.

Scope of This Directory

At a high level, this directory contains:

General-purpose file discovery utilities

YAML and shell inspection helpers

Inventory update and deployment bridge scripts

Each script is documented separately to avoid overloading this overview.
```

```
find.sh
Purpose

A hybrid file discovery and inspection utility designed to quickly locate and preview files by extension across the project.

It supports:

Non-interactive CLI usage

Interactive menu-driven exploration

This script is used primarily during:

Debugging

Code reviews

Documentation work

Auditing playbooks and configs

What It Does

Searches recursively for files by extension

Lists matching files or prints their contents

Supports multiple extensions in one command

Falls back to interactive mode if no arguments are provided

List files by extension
./find.sh sh
./find.sh yml yaml

Print matching files
./find.sh sh py js cat
./find.sh yml md show




update-inventory.sh
Purpose

A deployment bridge script that dynamically determines the target EC2 host and runs the appropriate Ansible playbooks.

This script handles the complexity of:

Local vs CI execution

Inventory generation

SSH key handling

Playbook invocation

It is one of the few scripts that directly connects Terraform outputs, AWS, and Ansible.

What It Does

Determines the EC2 public IP:

From EC2_IP env var, or

Via AWS CLI (by instance tag)

Verifies HTTP readiness on the target host

Chooses execution mode:

Local development

GitHub Actions / CI

Prepares inventory and SSH configuration

Executes Ansible playbooks:

Docker setup

Application deployment

Local Execution Behavior

When run locally:

Writes a temporary Ansible inventory file

Uses a local SSH key

Sources local environment variables

Runs playbooks directly

Example:

./update-inventory.sh



arrange_dashboards.sh
Purpose

Normalizes Grafana dashboard JSON files to ensure compatibility with file-based provisioning.

When dashboards are exported from Grafana, they often come wrapped inside a top-level "dashboard" object.
Grafana provisioning, however, expects a flattened structure.

This script automatically fixes that mismatch.

What It Does

Scans all dashboard JSON files in the Grafana dashboards directory

Detects wrapped dashboards (missing top-level "title")

Extracts and promotes key fields from the "dashboard" object:

title

uid

schemaVersion

version

panels

Rewrites the JSON into a clean, flat structure

Skips already-correct files (idempotent behavior)

Ensures correct file ownership and permissions for Grafana

Why This Exists

This solves a real-world monitoring issue:

Exported dashboards ≠ Provisionable dashboards

Without this script:

Grafana silently ignores dashboards

Dashboards fail to load during container startup

Debugging becomes difficult due to lack of clear errors

This script guarantees that all dashboards are:

Provisioning-ready

Consistent

Safe for automation pipelines

Example Usage

./arrange_dashboards.sh


renew_cert.sh
Purpose

Handles safe SSL certificate renewal by checking expiration before triggering renewal.

Prevents unnecessary certbot runs while ensuring certificates never expire.

What It Does

Reads certificate expiry date using certbot

Calculates remaining validity in days

If ≤ 30 days:

Triggers renewal via setup script

If > 30 days:

Skips renewal safely

Why This Exists

Certbot auto-renewal is not always guaranteed in:

Ephemeral environments

Custom setups without systemd timers

CI-driven infrastructure

This script provides a deterministic, controlled renewal mechanism.

Example Usage

./renew_cert.sh


setup_cert.sh
Purpose

Bootstraps SSL certificate issuance using DuckDNS + Certbot DNS-01 challenge.

Designed for first-run initialization of HTTPS in EdgePaaS.

What It Does

Validates required environment variables:

EMAIL_TO

DUCKDNS_TOKEN

Prepares secure DuckDNS credentials file

Issues certificate using DNS-01 challenge (no open ports required)

Stores a bootstrap flag to prevent repeated issuance

Reloads Nginx to apply certificates

Why DNS-01 (DuckDNS)?

Works without exposing ports publicly

Ideal for cloud + dynamic IP environments

Avoids HTTP challenge race conditions

Safe for automated provisioning

Idempotency Behavior

Runs only once (guarded by FIRST_RUN_DONE flag)

Skips issuance if certificate already exists and is valid

Example Usage

EMAIL_TO=you@example.com DUCKDNS_TOKEN=xxx ./setup_cert.sh


update_duckdns.sh
Purpose

Keeps the DuckDNS domain updated with the current public IP of the host.

Critical for dynamic IP environments like EC2.

What It Does

Fetches current public IP from an external service

Sends update request to DuckDNS API

Maps domain → current IP

Why This Exists

EC2 public IPs can change (especially without Elastic IPs)

DNS must stay in sync for:

SSL certificate validation

External access

API integrations

Example Usage

DUCKDNS_TOKEN=xxx ./update_duckdns.sh


Execution Philosophy (Applied)

Across all scripts in this directory:

Strict mode is enforced:
set -euo pipefail

All external dependencies are validated

Clear success and failure messages are printed

Scripts are designed to be:

Idempotent where possible

Environment-aware

Safe for repeated execution

Operational Boundaries

These scripts may:

Prepare environments

Fix integration mismatches

Trigger deployment workflows

They must never:

Replace Terraform provisioning

Embed business logic

Introduce hidden state mutations

In short:

Terraform defines
Ansible configures
Docker runs
scripts/ assists


This separation is intentional and critical for long-term maintainability.


