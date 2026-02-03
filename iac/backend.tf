# Remote backend for shared state, locking, and safe collaboration
terraform {
  backend "s3" {
    bucket         = "edgepaas-backend-tf"
    key            = "edgepaas/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "edgepaas-lock-tf"
    encrypt        = true
  }
}
