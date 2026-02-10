# ----------------------------
# Profile
# ----------------------------
#variable "profile" {
#  description = "Profile"
#  type        = string
#}

# ----------------------------
# VPC
# ----------------------------
variable "vpc_cidr" {
  description = "CIDR block for the VPC" # Platform-wide network range
  type        = string
  default     = "10.20.0.0/16"
}

# ----------------------------
# Subnets
# ----------------------------
variable "public_subnets" {
  description = "List of public subnet CIDRs" # Public subnets for edge nodes
  type        = list(string)
  default     = ["10.20.1.0/24", "10.20.2.0/24"]
}

variable "azs" {
  description = "Allowed availability zones" # AZs for public subnets
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

# ----------------------------
# Security Groups
# ----------------------------
variable "security_groups" {
  description = "Set of security groups to create" # SGs for edge nodes
  type        = set(string)
  default     = ["public-app"]
}

# ----------------------------
# CIDR Blocks
# ----------------------------
variable "cidr_blocks" {
  description = "Set of IPs in CIDR" # Allowed source IPs for ingress
  type        = set(string)
}

# ----------------------------
# Key Name
# ----------------------------
variable "key_name" {
  description = "SSH key name"
  type        = string
  default     = "tf-web-key"
}

# ----------------------------
# Cost Alert
# ----------------------------
variable "amount" {
  description = "Limit Amount"
  type        = number
}

variable "alert_emails" {
  description = "Emails for alert"
  type        = list(string)
}
