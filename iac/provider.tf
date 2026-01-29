# ============================================================
# EdgePaaS — Terraform Provider Configuration
# ============================================================
#
# Purpose:
# This file defines the *execution context* for Terraform.
# It answers the question:
#
#   “Where does Terraform run, and which APIs does it talk to?”
#
# What belongs here:
# - Terraform CLI version constraints
# - Provider declarations and versions
# - Global provider configuration (region, auth via env/profile)
#
# What does NOT belong here:
# - Any infrastructure logic
# - Any environment-specific decisions
# - Any resource definitions
#
# In EdgePaaS:
# - Terraform owns cloud primitives (VPC, EC2, EBS, networking)
# - CI/CD (GitHub Actions) will authenticate externally
# - Configuration management (Ansible) happens *after* provisioning
#
# This file should almost never change once stabilized.
# ============================================================

terraform {
  # Enforce a modern Terraform version to ensure:
  # - Stable provider behavior
  # - Consistent plan/apply semantics
  # - Access to newer language features (for_each, dynamic blocks, etc.)
  required_version = ">= 1.5.0"

  # Declare required providers explicitly so:
  # - CI pipelines are deterministic
  # - New contributors get consistent provider versions
  # - Future refactors don’t silently break infrastructure
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

# ------------------------------------------------------------
# AWS Provider
# ------------------------------------------------------------
#
# This provider defines *which AWS account and region*
# EdgePaaS infrastructure is provisioned into.
#
# Authentication is intentionally NOT hardcoded here.
# Terraform will rely on:
# - AWS CLI profiles (local development)
# - Environment variables (CI/CD via GitHub Actions)
#
# This keeps the provider:
# - Secure
# - Portable
# - Environment-agnostic
#
provider "aws" {
  region = "us-east-1"
}
