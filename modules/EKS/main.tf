# Creating EKS Cluster
resource "aws_eks_cluster" "eks" {
  name     = "AWS-EKS"
  role_arn = var.master_arn

  vpc_config {
    subnet_ids = [var.public_subnet_az1_id, var.public_subnet_az2_id]
  }

  tags = {
    key   = var.env
    value = var.type
  }
}

# Using Data Source to get all Avalablility Zones in Region
data "aws_availability_zones" "available_zones" {}

# Fetching Ubuntu 20.04 AMI ID
data "aws_ami" "amazon_linux_2" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"]
}

# Creating kubectl server
resource "aws_instance" "kubectl-server" {
  ami                         = data.aws_ami.amazon_linux_2.id
  key_name                    = var.key_name
  instance_type               = var.instance_size
  associate_public_ip_address = true
  subnet_id                   = var.public_subnet_az1_id
  vpc_security_group_ids      = [var.eks_security_group_id]

  tags = {
    Name = "${var.project_name}-kubectl"
    Env  = var.env
    Type = var.type
  }
}

# Creating Worker Node Group
resource "aws_eks_node_group" "node-grp" {
  cluster_name    = aws_eks_cluster.eks.name
  node_group_name = "Worker-Node-Group"
  node_role_arn   = var.worker_arn
  subnet_ids      = [var.public_subnet_az1_id, var.public_subnet_az2_id]
  capacity_type   = "ON_DEMAND"
  disk_size       = 20
  instance_types  = [var.instance_size]

  remote_access {
    ec2_ssh_key               = var.key_name
    source_security_group_ids = [var.eks_security_group_id]
  }

  labels = {
    env = "Prod"
  }

  scaling_config {
    desired_size = 2
    max_size     = 2
    min_size     = 1
  }

  update_config {
    max_unavailable = 1
  }
}


##################   ingress-nginx   ##################

resource "helm_release" "ingress-nginx" {
  namespace = "nginx-ingress"
  create_namespace = true

  name                = "ingress-nginx"
  repository          = "https://kubernetes.github.io/ingress-nginx"
  chart               = "ingress-nginx"
  wait                = true
  cleanup_on_fail     = true
  force_update        = true
  replace             = true
  lint                = true

  set {
    name  = "rbac.create"
    value = true
  }

  set {
    name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-type"
    value = "nlb"
  }

  set {
    name  = "controller.service.type"
    value = "LoadBalancer"
  }

  set {
    name  = "controller.image.allowPrivilegeEscalation"
    value = false
  }
   values = [
     <<-EOT
     controller:
       service:
         type: LoadBalancer
         annotations:
           service.beta.kubernetes.io/aws-load-balancer-name: apps-ingress
           service.beta.kubernetes.io/aws-load-balancer-type: external
           service.beta.kubernetes.io/aws-load-balancer-scheme: internet-facing
           service.beta.kubernetes.io/aws-load-balancer-nlb-target-type: ip
           service.beta.kubernetes.io/aws-load-balancer-healthcheck-protocol: http
           service.beta.kubernetes.io/aws-load-balancer-healthcheck-path: /healthz
           service.beta.kubernetes.io/aws-load-balancer-healthcheck-port: 10254
       image:
         allowPrivilegeEscalation: false
     EOT
   ]

   depends_on = [aws_eks_node_group.node-grp]
}