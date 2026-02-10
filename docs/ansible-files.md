# Ansible Files Reference — EdgePaaS

```
This document describes each file and directory inside the ansible/ layer, explaining what it does, when it runs, and how it fits into the deployment pipeline.

This is the operational contract of the Ansible layer.

Entry & Orchestration
run.yml

Role: Primary orchestration entrypoint

This is the only playbook that should be executed directly.

Responsibilities

Defines execution order

Imports all other playbooks

Ensures correct sequencing and failure propagation

Flow

Preparation

Docker installation & setup

Application deployment

Post-deployment validation

All other playbooks are called from here, never manually chained.

Preparation Phase
prep.yml

Role: Host readiness & environment validation

This playbook prepares the target host before any deployment logic runs.

Responsibilities

Validate required variables

Ensure required packages are installed

Prepare directories and permissions

Configure OS-level dependencies

Install and configure Nginx (base)

This playbook guarantees the host is deployment-ready.

Failures here stop the pipeline immediately.

Docker Phase
docker.yml

Role: Docker runtime setup

Handles everything required to safely run containers on the host.

Responsibilities

Install Docker engine

Configure Docker daemon

Ensure Docker is running and enabled

Prepare disk and filesystem layout

Validate Docker usability

This playbook is idempotent and safe to re-run.

Deployment Phase
deploy.yml

Role: Application deployment & traffic switching

This is the core deployment engine of EdgePaaS.

Responsibilities

Determine active and inactive deployment slots

Pull application image

Stop inactive container

Start new container in inactive slot

Perform container-level health checks

Switch Nginx traffic

Persist deployment state

Deployment follows strict blue/green rules:

No traffic switch without passing health checks

No cleanup before success

No implicit rollback

Validation & Finalization
checks.yml

Role: Post-deployment verification and cleanup

Runs after traffic has been switched.

Responsibilities

Port reachability checks

HTTP endpoint validation

Application health verification

Success or failure signaling

Cleanup old containers and resources

This is the last gate before declaring deployment success.

Configuration Files
ansible.cfg

Role: Ansible execution behavior

Controls Ansible runtime behavior, including:

SSH settings

Privilege escalation

Output formatting

Timeout handling

This ensures consistent behavior across:

Local runs

CI/CD pipelines

Remote executions

local.ini

Role: Local development inventory

Used for:

Testing playbooks locally

Debugging without CI

Dry-running logic safely

This file is never used in production pipelines.

Supporting Directories
files/

Role: Static assets

Contains files copied directly to target hosts, such as:

Shell scripts

Configuration fragments

SQL or data files

Files here are not templated.

templates/

Role: Jinja2 templates

Contains templated configuration files, including:

Nginx configs

Service definitions

Runtime configuration files

Templates are rendered dynamically using Ansible variables.

Execution Guarantees

The Ansible layer guarantees:

Deterministic execution order

Explicit failure points

No hidden side effects

Environment-aware behavior

Safe re-runs where applicable

If a deployment succeeds, it is provably healthy.
If it fails, it fails loudly and early.

Summary
Component	Responsibility
run.yml	Orchestration entrypoint
prep.yml	Host & environment preparation
docker.yml	Docker runtime setup
deploy.yml	Blue/green deployment logic
checks.yml	Validation & cleanup
ansible.cfg	Execution behavior
local.ini	Local testing
files/	Static assets
templates/	Dynamic configs

```
