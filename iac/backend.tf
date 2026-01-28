
terraform {
  backend "s3" {
    bucket         = "micropaas-backend-tf"
    key            = "micropaas/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "micropaas-lock-tf"
    encrypt        = true
  }
}
