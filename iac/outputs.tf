# ----------------------------
# VPC
# ----------------------------
output "vpc_id" {
  description = "VPC ID" # Platform VPC
  value       = aws_vpc.main.id
}

# ----------------------------
# Public Subnets
# ----------------------------
output "public_subnet_ids" {
  description = "Public subnet IDs" # For routing, provisioning, or CI/CD
  value       = [for s in aws_subnet.public : s.id]
}

# ----------------------------
# Internet Gateway
# ----------------------------
output "internet_gateway_id" {
  description = "Internet Gateway ID" # Needed for public routing
  value       = aws_internet_gateway.igw.id
}

# ----------------------------
# Security Groups
# ----------------------------
output "security_group_ids" {
  description = "Map of security group names to IDs" # Allows dynamic assignment in future nodes
  value       = { for k, sg in aws_security_group.this : k => sg.id }
}

# ----------------------------
# EC2 Instances
# ----------------------------
output "ec2_instance_ids" {
  description = "Map of EC2 instance names to IDs" # Platform node identifiers
  value       = { for k, i in aws_instance.this : k => i.id }
}

output "ec2_public_ips" {
  description = "Public IPs of EC2 instances (only public subnets)" # For CI/CD, SSH, or routing
  value       = { for k, i in aws_instance.this : k => i.public_ip if i.public_ip != "" }
}
