```text
GitHub Workflows — EdgePaaS

This document explains each GitHub Actions workflow in EdgePaaS, why it exists, and how it fits into the end-to-end platform pipeline.
The are pipeline orchestrators for infrastructure, build, deployment, and reporting.

Design Philosophy

The EdgePaaS CI/CD layer follows these rules:

Infrastructure first, application second

Immutable builds

Blue/green deployments only

OIDC-based AWS access (no static keys)

Everything is reproducible from GitHub Actions

Failures must be visible and reported

Workflow Files Overview

.github/workflows/
├─ edgepaas.yml     # Full production pipeline (Terraform → Build → Deploy → Report)
├─ cached_version.yml  # Build optimization, Speed & experimentation
├─ test.yml         # Experimental / validation pipeline
└─ README.md        # Placeholder (directory marker)

edgepaas.yml

Purpose

Primary production pipeline for EdgePaaS.

This workflow is the single source of truth for:

Infrastructure provisioning

Docker image build & push

Application deployment via Ansible

Final success/failure reporting

It is intentionally manual (workflow_dispatch) to avoid accidental infra changes.

Trigger

workflow_dispatch:
  inputs:
    tf_action:
      description: Terraform action (apply / destroy)
      default: apply

This allows:

apply → full environment provisioning & deployment

destroy → controlled teardown

Global Environment

The workflow defines strict environment boundaries:

Terraform config (version, directory, variables)

Docker metadata (user, app name, tags)

AWS region and role (OIDC)

Feature flags (cache control)

These values propagate across all jobs.

Job: terraform

Role

Infrastructure authority

This job is responsible for everything cloud-related.

Responsibilities

Authenticate to AWS using OIDC

Initialize Terraform backend

Format & validate Terraform code

Plan infrastructure changes

Apply or destroy infrastructure based on input

Guarantees

No build or deploy happens if Terraform fails

Destroy explicitly blocks downstream jobs

State consistency is enforced before changes

Job: build

Role

Immutable application packaging

Runs only if Terraform succeeds and is not destroy.

Responsibilities

Authenticate to Docker Hub

Build application image

Produce blue and green variants

Push versioned images using commit SHA

Design Choice

Blue and green images are built ahead of deployment

No image mutation on the server

No latest dependency in production

This ensures repeatable rollbacks.

Job: deploy

Role

Controlled application rollout

This job bridges CI → runtime infrastructure.

Responsibilities

Discover EC2 instance dynamically

Prepare SSH access securely

Generate runtime inventory

Run Ansible orchestration (run.yml)

Inject runtime secrets safely

Enforce blue/green switching rules

Key Characteristics

Inventory is generated dynamically

Secrets never touch the repo

Ansible remains the deployment authority

GitHub Actions never “deploys directly”

Job: final_report

Role

Outcome reporting & observability

This job exists to answer one question:

“Did the platform deployment succeed — end to end?”

Responsibilities

Collect job-level results

Compute overall pipeline status

Generate a concise summary

Send email notifications

Failures are not silent.

test.yml

Purpose

Experimental / validation pipeline

This workflow is used for:

Testing pipeline logic

Validating Docker builds

Verifying Ansible changes

Debugging without touching Terraform destroy/apply flow

It mirrors most of the production pipeline without full infra control.

Key Differences from edgepaas.yml

No Terraform stage

Faster iteration

Used for testing Ansible + Docker changes

Safe experimentation space

This prevents breaking the production pipeline during development.

README.md

Currently acts as:

Directory marker

Placeholder for future high-level CI/CD documentation

(Not operationally significant)

Execution Flow Summary

workflow_dispatch
        ↓
Terraform (OIDC + IaC)
        ↓
Docker Build (blue & green)
        ↓
Ansible Deploy (blue/green switch)
        ↓
Final Report (email + status)

Guarantees Provided by This Layer

Infrastructure and application lifecycle are tightly coupled

No deployment without known-good infrastructure

No traffic switch without health checks

No silent failures

No static credentials

No manual server mutation
```
