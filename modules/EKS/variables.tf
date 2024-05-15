# Environment
variable "env" {
  type = string
}

# Type
variable "type" {
  type = string
}

# Stack name
variable "project_name" {
  type = string
}

# Public subnet AZ1
variable "public_subnet_az1_id" {
  type = string
}

# Public subnet AZ2
variable "public_subnet_az2_id" {
  type = string
}

# Security Group
variable "eks_security_group_id" {
  type = string
}

# Master ARN
variable "master_arn" {
  type = string
}

# Worker ARN
variable "worker_arn" {
  type = string
}

# Key name
variable "key_name" {
  type = string
}

# Worker Node & Kubectl instance size
variable "instance_size" {
  type = string
}

variable "kubernetes_cluster_role_binding" {}

variable "kubernetes_service_account" {}

# VPC ID
variable "vpc_id" {
  type = string
}

variable "region" {
  type = string
}