# configure aws provider
provider "aws" {
  region  = var.region
  profile = "prithviv"
}

# configure backend
terraform {
  backend "s3" {
    bucket         = "prithviv-terraform"
    key            = "terraform.tfstate"
    region         = "us-east-2"
    profile        = "prithviv"
    dynamodb_table = "terraform-state-lock-dynamodb-prithviv"
  }
}