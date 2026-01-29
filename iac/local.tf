# Local definitions for EC2 instances and roles in the platform
locals {
  ec2_instances = {
    public_app = {
      subnet_type   = "public"     # Subnet type (public/private) for this edge node
      instance_type = "t3.micro"   # EC2 instance size
      sg            = "public-app" # Security group assigned to this node
    }
  }
}
