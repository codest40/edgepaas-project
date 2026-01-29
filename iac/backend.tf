# Remote backend for shared state, locking, and safe collaboration
terraform {
  backend "s3" {
    bucket         = "edgepaas-backend-tf"        # Central S3 bucket for Terraform state
    key            = "edgepaas/terraform.tfstate" # Logical state path for this platform
    region         = "us-east-1"                  # Backend region (must match bucket)
    dynamodb_table = "edgepaas-lock-tf"           # State locking to prevent concurrent applies
    encrypt        = true                         # Server-side encryption for state file
  }
}
