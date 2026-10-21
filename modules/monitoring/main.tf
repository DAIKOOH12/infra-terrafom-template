# Pre-creates the CloudWatch log group EKS control-plane logging writes to,
# so retention is Terraform-managed instead of defaulting to "never expire".
resource "aws_cloudwatch_log_group" "eks_cluster" {
  count             = var.enabled ? 1 : 0
  name              = "/aws/eks/${var.cluster_name}/cluster"
  retention_in_days = var.retention_in_days

  tags = var.tags
}
