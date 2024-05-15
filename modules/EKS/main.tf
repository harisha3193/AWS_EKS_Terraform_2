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

data "aws_eks_cluster" "cluster" {
  name = aws_eks_cluster.eks.id
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





resource "kubernetes_deployment" "ingress" {
  metadata {
    name      = "alb-ingress-controller"
    namespace = "kube-system"
    labels = {
      "app.kubernetes.io/name"       = "alb-ingress-controller"
      "app.kubernetes.io/version"    = "v1.1.5"
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        "app.kubernetes.io/name" = "alb-ingress-controller"
      }
    }

    template {
      metadata {
        labels = {
          "app.kubernetes.io/name"    = "alb-ingress-controller"
          "app.kubernetes.io/version" = "v1.1.5"
        }
      }

      spec {
        dns_policy                       = "ClusterFirst"
        restart_policy                   = "Always"
        service_account_name             = var.kubernetes_service_account.metadata[0].name
        termination_grace_period_seconds = 60

        container {
          name              = "alb-ingress-controller"
          image             = "docker.io/amazon/aws-alb-ingress-controller:v1.1.5"
          image_pull_policy = "Always"

          args = [
            "--ingress-class=alb",
            "--cluster-name=${data.aws_eks_cluster.cluster.id}",
            "--aws-vpc-id=${var.vpc_id}",
            "--aws-region=${var.region}",
            "--aws-max-retries=10",
          ]

#          volume_mount {
#            mount_path = "/var/run/secrets/kubernetes.io/serviceaccount"
#            name       = kubernetes_service_account.ingress.default_secret_name
#            read_only  = true
#          }

          port {
            name           = "health"
            container_port = 10254
            protocol       = "TCP"
          }

          readiness_probe {
            http_get {
              path   = "/healthz"
              port   = "health"
              scheme = "HTTP"
            }

            initial_delay_seconds = 30
            period_seconds        = 60
            timeout_seconds       = 3
          }

          liveness_probe {
            http_get {
              path   = "/healthz"
              port   = "health"
              scheme = "HTTP"
            }

            initial_delay_seconds = 60
            period_seconds        = 60
          }
        }

 #       volume {
 #         name = var.kubernetes_service_account.default_secret_name

 #         secret {
 #           secret_name = var.kubernetes_service_account.default_secret_name
 #         }
 #       }

      }
    }
  }

  depends_on = [var.kubernetes_cluster_role_binding]
}