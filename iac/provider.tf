
terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = ">= 5.0"
  }
}


provider "aws" {
  alias  = "use1"
  region = "us-east-1"
}
