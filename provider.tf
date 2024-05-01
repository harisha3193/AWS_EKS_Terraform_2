# configure aws provider
provider "aws" {
  region  = var.region
  #comment profile and uncomment access and secret key when checked-in in github
  profile = "harisha3193"
  # access_key = var.prod_aws_key
  # secret_key = var.prod_aws_secret
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