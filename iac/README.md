# ============================================================
#  FOLDER 5 — ATLAS STAGE “LOOPING PLAYGROUND” & PROD-READY EC2 SETUP
# ============================================================

# ------------------------------------------------------------
#  OVERVIEW
# ------------------------------------------------------------
This folder demonstrates Terraform looping patterns and builds
a production-ready VPC + EC2 architecture, forming a solid
foundation for CI/CD integration.

# ------------------------------------------------------------
#  LEARNING PATTERNS COVERED
# ------------------------------------------------------------

## Loops with for_each
Used for unique, keyed resources:
- Security Groups (set(string) / map(string))
- Security Group Rules (map(object(...)))
- Subnets (set(string) / list(string))
- EC2 Instances (map(object(...)))

## Loops with count
Used for identical, numeric, or repeated resources:
- NAT Gateways (count = length(var.public_subnets))
- Elastic IPs (count = 1..n)

## Input Patterns / Data Structures
+-------------------+-----------------------------------------------+
| Pattern           | Usage                                         |
+-------------------+-----------------------------------------------+
| set(string)       | Identity-driven for_each                      |
| map(object(...))  | Detailed configuration-driven for_each       |
| list(string)      | Count-based resource creation                 |
+-------------------+-----------------------------------------------+

## Output Mapping
- { for k, v in aws_instance.this : k => v.id }
- Enables easy reference of dynamically created resources

# ------------------------------------------------------------
#  PROD-READY VPC + EC2 ARCHITECTURE
# ------------------------------------------------------------

### Resources Created
- VPC — Single CIDR
- Subnets
  - Public subnet (app & bastion)
  - Private subnet (private app)
- Internet Gateway — Enables public subnet routing
- NAT Gateway — Provides outbound access for private subnet
- Security Groups — Three SGs: bastion, app, private-app
- EC2 Instances — Three instances:
  - bastion → Public subnet, SSH + SSM access
  - app → Public subnet, app-ready
  - private-app → Private subnet, app-ready
- AMI Lookup — Amazon Linux 2023

# ------------------------------------------------------------
#  LOOPING & DESIGN HIGHLIGHTS
# ------------------------------------------------------------
- for_each is used for unique, keyed resources (subnets, security groups, EC2s)
- count is used for identical / numeric resources (NAT Gateway, EIP)
- Data-driven design — all configuration comes from variables.tf and terraform.tfvars
- Future-ready — structure allows easy conversion into modules and CI/CD pipelines

# ------------------------------------------------------------
#  WHY THIS MATTERS
# ------------------------------------------------------------
- Reinforces practical use of loops (for_each vs count) in Terraform
- Demonstrates mapping complex objects like security group rules and EC2 configs
- Sets up a reliable, production-lean environment without over-engineering
- Creates a playground for integrating SSM access, multi-AZ deployments, and CI/CD next
