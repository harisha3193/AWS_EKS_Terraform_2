# IAM Wokrer Node Instance Profile
output "instance_profile" {
  value = aws_iam_instance_profile.worker.name
}

# IAM Role Master's ARN
output "master_arn" {
  value = aws_iam_role.master.arn
}

# IAM Role Worker's ARN
output "worker_arn" {
  value = aws_iam_role.worker.arn
}

output "kubernetes_cluster_role_binding" {
  value = kubernetes_cluster_role_binding.ingress
}

output "kubernetes_service_account" {
    value = kubernetes_service_account.ingress
}