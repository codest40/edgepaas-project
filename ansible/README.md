#Ansible Layer — EdgePaaS

## Purpose

```
The ansible/ directory defines the configuration, deployment, and orchestration layer of EdgePaaS.

Its responsibility is to take a ready infrastructure and a built application image, then:

Prepare the host

Install and configure required services

Deploy the application using blue/green strategy

Perform health checks

Finalize traffic switching and cleanup

This layer is where infrastructure becomes a running platform.

Why Ansible in EdgePaaS

EdgePaaS intentionally separates responsibilities:

Terraform (iac/) provisions infrastructure

Docker (docker/) defines runtime behavior

Ansible (ansible/) configures hosts and executes deployments

Ansible is used here because it excels at:

Declarative host configuration

Idempotent execution

Clear task ordering

Remote orchestration without agents

This makes deployments predictable, auditable, and repeatable.

What This Layer Handles

The Ansible layer is responsible for:

Validating required environment variables

Preparing EC2 hosts (users, packages, directories)

Installing and configuring Docker

Installing and configuring Nginx

Deploying Docker containers using blue/green strategy

Performing health and readiness checks

Switching traffic safely

Rolling forward or failing hard with alerts

It assumes:

Infrastructure already exists

Docker images are already built and pushed

Secrets are injected via environment variables or CI/CD

Deployment Philosophy

EdgePaaS uses a self-managed blue/green deployment model:

One container is ACTIVE

One container is INACTIVE

Only the inactive slot is ever deployed to

Traffic switches only after health checks pass

The previous version is removed only after success

There is no partial deployment and no silent rollback.

Failures are:

Detected early

Logged explicitly

Alerted immediately

Stopped before traffic is switched

Execution Flow (High Level)

The Ansible workflow is orchestrated through a single entry playbook:

run.yml


Execution follows this strict order:

Preparation phase

Environment validation

Host setup

OS, users, and base services

Database client setup

Nginx installation

Docker phase

Docker installation

Docker daemon configuration

Disk and filesystem preparation

Deployment phase

Resolve active/inactive slots

Pull application images

Stop inactive containers

Start new container

Perform health checks

Switch Nginx traffic

Persist active state

Post-deployment checks

Port checks

HTTP checks

Health endpoint validation

Final success or failure alert

Cleanup old containers

Environment Awareness

This layer is CI/CD aware.

It dynamically adapts based on execution context:

Local execution

SSH-based remote execution

GitHub Actions pipelines

Host resolution, inventory handling, and variable sourcing adjust automatically without changing playbooks.

Design Principles

All Ansible code in EdgePaaS follows these rules:

Explicit failures over silent success

No hidden defaults

No manual color or slot control

Idempotent where possible

Clear logging and debug output

One responsibility per playbook

If something goes wrong, the pipeline fails loudly and early.

Scope of This Directory

At a glance, this directory contains:

Entry orchestration playbooks

Host preparation logic

Docker installation logic

Deployment pipeline logic

Health check and alerting logic

Templates and static files used during deployment

Detailed descriptions of each playbook, template, and file are documented separately.

```
