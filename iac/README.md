# EdgePaaS — Infrastructure as Code (IAC)

```text
The iac/ directory contains the Terraform code and helper scripts to provision, configure, and manage the cloud infrastructure for EdgePaaS. This layer is responsible for creating the network, compute resources, storage, and cost monitoring before application deployment via Ansible.

Purpose

EdgePaaS IAC provides:

Automated provisioning of AWS resources (VPC, subnets, EC2, security groups, EBS volumes).

Remote state management using S3 + DynamoDB locks to ensure team-safe Terraform operations.

Cost control via AWS Budgets and notifications.

Infrastructure reproducibility for dev, staging, and production environments.

Integration with Ansible via dynamic inventory updates after provisioning.

Directory Structure

iac/
├── backend.tf         # S3/DynamoDB remote state backend
├── budget.tf          # AWS cost alert/budget resources
├── local.tf           # Local definitions (EC2 instances, roles)
├── main.tf            # Core infrastructure (VPC, subnets, security groups, EC2, EBS)
├── outputs.tf         # Outputs (IDs, IPs) for Ansible and CI/CD
├── provider.tf        # Terraform provider configuration (AWS)
├── terraform.tfvars   # Environment-specific variable values
├── variables.tf       # Input variables definitions
├── boot/              # Bootstrapping infrastructure (S3 bucket, DynamoDB)
│   ├── main.tf
│   ├── provider.tf
│   ├── s3.tf
│   ├── dynamodb.tf
│   ├── terraform.tfvars
│   └── variables.tf
├── runner.sh          # Helper script to run `terraform apply` or `destroy`
└── find.sh            # Helper script to explore Terraform files

Key Files Explained

backend.tf

Configures remote Terraform state in an S3 bucket.

Uses DynamoDB table for state locking to prevent concurrent modifications.

Ensures team-safe and auditable deployments.

boot/

Bootstraps the remote backend infrastructure:

s3.tf → Creates the S3 bucket for Terraform state, with versioning and server-side encryption.

dynamodb.tf → Creates the DynamoDB table for state locking.

provider.tf → AWS provider config for bootstrapping.

terraform.tfvars → Provides backend-specific variables.

variables.tf → Declares variables for the bootstrap resources.

This is run only once when initializing the environment.

provider.tf

Sets Terraform version requirement and provider source/version (aws >= 5.0).

Configures AWS provider with region (e.g., us-east-1) and authentication via AWS CLI profile or environment variables.

main.tf

Core infrastructure provisioning:

Networking

VPC, public subnets, internet gateway, and route tables.

Security

Security groups for edge nodes with dynamic ingress rules.

Compute

EC2 instances for EdgePaaS nodes, using Amazon Linux 2023.

Storage

EBS volumes for Docker or app data.

Tags

Consistent naming conventions for easier management.

local.tf

Local Terraform definitions for EC2 instances and their roles.

Allows defining per-instance attributes (subnet type, security group, instance type) without hardcoding in main.tf.

outputs.tf

Exposes resource IDs and IPs for Ansible, CI/CD, and debugging.

Includes VPC ID, public subnet IDs, internet gateway ID, security group IDs, EC2 instance IDs, and public IPs.

variables.tf & terraform.tfvars

Declare all configurable parameters for EdgePaaS infrastructure.

Examples: VPC CIDR, subnet CIDRs, security groups, SSH key, budget limits, email alerts.

budget.tf

Creates AWS Budgets with notifications.

Sends email alerts if cost exceeds thresholds (50% actual, 80% forecasted).

runner.sh

Wrapper script for applying or destroying Terraform infrastructure.

Automatically:

Runs terraform init, fmt, validate, plan, apply.

Updates Ansible inventory via update-inventory.sh after provisioning.

Usage:

./runner.sh apply   # Provision infrastructure
./runner.sh destroy # Tear down infrastructure

find.sh

A helper to explore Terraform files interactively.

Useful for quick previews of resource definitions and variables.

Workflow

Bootstrap backend (boot/) once for S3/DynamoDB state.

Define infrastructure via main.tf, local.tf, budget.tf.

Apply Terraform using runner.sh apply.

Terraform outputs feed into Ansible dynamic inventory.

Deploy application and configuration using Ansible.

Monitor costs via AWS Budgets.
```
