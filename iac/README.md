# ============================================================
#  EDGEPAAS — INFRASTRUCTURE AS CODE (IAC)
# ============================================================

The `iac/` directory contains all Terraform code and helper scripts
used to provision, configure, and manage the cloud infrastructure
for EdgePaaS.

This layer builds the foundation:

Network → Compute → Storage → Cost Controls → Outputs → Ansible Integration

Application deployment happens only after this layer is complete.


# ============================================================
#  PURPOSE
# ============================================================

EdgePaaS IAC provides:

- Automated provisioning of AWS infrastructure
- Remote Terraform state management (team-safe)
- Infrastructure reproducibility across environments
- Cost visibility and alerting
- Integration with Ansible after provisioning

This ensures infrastructure is:

- Declarative
- Version-controlled
- Reproducible
- Safe for team collaboration


# ============================================================
#  DIRECTORY STRUCTURE
# ============================================================

iac/
├── backend.tf
├── budget.tf
├── local.tf
├── main.tf
├── outputs.tf
├── provider.tf
├── terraform.tfvars
├── variables.tf
├── boot/
│   ├── main.tf
│   ├── provider.tf
│   ├── s3.tf
│   ├── dynamodb.tf
│   ├── terraform.tfvars
│   └── variables.tf
├── runner.sh
└── find.sh


# ============================================================
#  CORE CONCEPTS
# ============================================================

This IAC layer enforces:

- Remote state locking
- Deterministic provisioning
- Infrastructure modularity
- Clear separation between bootstrap and main infrastructure
- Clean integration with configuration management (Ansible)


# ============================================================
#  backend.tf — REMOTE STATE CONFIGURATION
# ============================================================

Purpose:
- Store Terraform state remotely in S3.
- Prevent concurrent modifications using DynamoDB locking.

Why It Matters:
- Prevents state corruption.
- Enables team-safe operations.
- Makes infrastructure auditable and recoverable.

Backend Components:
- S3 bucket (state storage)
- DynamoDB table (state lock)


# ============================================================
#  boot/ — BACKEND BOOTSTRAP LAYER
# ============================================================

This folder creates the backend infrastructure itself.

Run ONLY once when initializing a new environment.

Contents:

s3.tf
- Creates S3 bucket for Terraform state.
- Enables versioning.
- Enables server-side encryption.

dynamodb.tf
- Creates DynamoDB table for state locking.
- Ensures safe concurrent operations.

provider.tf
- AWS provider configuration specific to bootstrap.

variables.tf
- Declares bootstrap input variables.

terraform.tfvars
- Provides backend-specific values.

Design Rule:
Bootstrap infrastructure must exist before remote backend can be used.


# ============================================================
#  provider.tf — AWS PROVIDER CONFIGURATION
# ============================================================

Defines:

- Terraform version requirement
- AWS provider source and version (aws >= 5.0)
- AWS region (e.g., us-east-1)

Authentication:
- AWS CLI profile
- Environment variables

Guarantee:
Consistent provider behavior across environments.


# ============================================================
#  main.tf — CORE INFRASTRUCTURE
# ============================================================

This file provisions primary infrastructure resources.

Networking:
- VPC
- Public subnets
- Internet gateway
- Route tables

Security:
- Security groups
- Dynamic ingress rules

Compute:
- EC2 instances (Amazon Linux 2023)

Storage:
- EBS volumes for Docker/app data

Tagging:
- Consistent naming conventions
- Environment-aware tagging


# ============================================================
#  local.tf — INSTANCE DEFINITIONS
# ============================================================

Purpose:
- Define per-instance attributes cleanly.
- Avoid hardcoding inside main.tf.

Examples:
- Instance type
- Subnet selection
- Security group assignment
- Node roles

Benefit:
Improves flexibility and readability.


# ============================================================
#  outputs.tf — INFRASTRUCTURE CONTRACT
# ============================================================

Exposes values required by:

- Ansible
- CI/CD
- Debugging

Examples:
- VPC ID
- Subnet IDs
- Security group IDs
- EC2 instance IDs
- Public IP addresses

Purpose:
Creates clean handoff from Terraform → Ansible.


# ============================================================
#  variables.tf & terraform.tfvars
# ============================================================

variables.tf:
- Declares all configurable parameters.

terraform.tfvars:
- Supplies environment-specific values.

Examples:
- VPC CIDR blocks
- Subnet CIDRs
- SSH key name
- Budget thresholds
- Alert email addresses

Guarantee:
Infrastructure remains environment-agnostic and configurable.


# ============================================================
#  budget.tf — COST CONTROL
# ============================================================

Creates AWS Budgets resources.

Features:
- Cost thresholds (e.g., 50% actual, 80% forecasted)
- Email notifications

Purpose:
Prevent cost overruns.
Provide early financial visibility.
Protect small environments from runaway usage.


# ============================================================
#  runner.sh — TERRAFORM EXECUTION WRAPPER
# ============================================================

Wrapper around Terraform CLI commands.

Automatically runs:

- terraform init
- terraform fmt
- terraform validate
- terraform plan
- terraform apply OR destroy

After successful apply:
- Updates Ansible inventory dynamically.

Usage:

./runner.sh apply
./runner.sh destroy

Purpose:
Standardize Terraform execution.
Reduce human error.
Ensure consistent workflow.


# ============================================================
#  find.sh — EXPLORATION HELPER
# ============================================================

Purpose:
- Explore Terraform files interactively.
- Quickly preview resource definitions and variables.

Useful for:
- Debugging
- Auditing
- Learning resource structure


# ============================================================
#  END-TO-END INFRASTRUCTURE WORKFLOW
# ============================================================

1. Run boot/ once to create:
   - S3 backend bucket
   - DynamoDB lock table

2. Configure infrastructure variables.

3. Execute:

   ./runner.sh apply

4. Terraform provisions:
   - Network
   - Security
   - EC2
   - EBS
   - Budgets

5. Outputs feed into Ansible dynamic inventory.

6. Ansible deploys application and configuration.

7. AWS Budgets monitor cost continuously.


# ============================================================
#  ARCHITECTURAL GUARANTEES
# ============================================================

- Remote state safety via S3 + DynamoDB
- Deterministic provisioning
- Clean separation of bootstrap vs infrastructure
- Cost visibility baked in
- Infrastructure reproducibility
- Smooth Terraform → Ansible integration
- Environment-agnostic configuration

This layer ensures the cloud foundation is:

Stable.
Reproducible.
Auditable.
Safe for collaboration.
