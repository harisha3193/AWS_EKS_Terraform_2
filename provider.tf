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
    bucket         = "konvoy-terraform-bucket"
    key            = "terraform.tfstate"
    region         = "us-east-2"
    profile        = "harisha3193"
    dynamodb_table = "terraform-state-lock-dynamodb-konvoy"
  }
}

provider "helm" {
  kubernetes {
    /* host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
      command     = "aws"
    } */

    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
}

data "aws_eks_cluster" "cluster" {
  name = module.eks.aws_eks_cluster_eks.id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.aws_eks_cluster_eks.id
}