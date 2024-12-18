provider "aws" {
  region = "us-east-1"
}

terraform {
  backend "s3" {
    bucket         = "skubestore-terraform-state-bucket"
    key            = "terraform/state.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}
