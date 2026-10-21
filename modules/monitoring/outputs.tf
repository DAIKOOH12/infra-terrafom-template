output "log_group_name" {
  value = var.enabled ? aws_cloudwatch_log_group.eks_cluster[0].name : null
}

output "log_group_arn" {
  value = var.enabled ? aws_cloudwatch_log_group.eks_cluster[0].arn : null
}
