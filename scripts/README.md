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


Design Notes

CI-safe and idempotent

Strict failure handling

Explicit logging for each step

No silent fallbacks
