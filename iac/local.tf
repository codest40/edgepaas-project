locals {
  ec2_instances = {
    public_app = {
      subnet_type   = "public"
      instance_type = "t3.micro"
      sg            = "public-app"
    }
  }
}
