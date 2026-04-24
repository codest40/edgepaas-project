# Remote backend for shared state, locking, and safe collaboration
terraform {
  backend "s3" {
    bucket         = "kubdeploy-backend-tf"
    key            = "kubdeploy/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "kubdeploy-lock-tf"
    encrypt        = true
  }
}
