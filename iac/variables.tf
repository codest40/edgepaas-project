# ----------------------------
# VPC
# ----------------------------
variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.20.0.0/16"
}

# ----------------------------
# Subnets
# ----------------------------
variable "public_subnets" {
  description = "List of public subnet CIDRs"
  type        = list(string)
  default     = ["10.20.1.0/24", "10.20.2.0/24"]
}

variable "azs" {
  description = "Allowed availability zones"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

# ----------------------------
# Security Groups
# ----------------------------
variable "security_groups" {
  description = "Set of security groups to create"
  type        = set(string)
  default     = ["public-app"]
}

# ----------------------------
# Cidr Block
# ----------------------------
variable "cidr_blocks" {
  description = "Set of IPs in cidr"
  type        = set(string)
}

# ----------------------------
# Optional Key Name
# ----------------------------
variable "key_name" {
  description = "SSH key name (optional, for bastion)"
  type        = string
  default     = "tf-web-key"
}
