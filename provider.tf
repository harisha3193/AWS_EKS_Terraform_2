# configure aws provider
provider "aws" {
  region  = var.region
  profile = "konvoy"
}

# configure backend
terraform {
  backend "s3" {
    bucket         = "konvoy-terraform"
    key            = "terraform.tfstate"
    region         = "us-east-2"
    profile        = "konvoy"
    dynamodb_table = "terraform-state-lock-dynamodb-konvoy"
  }
}