variable "name" {
  type        = string
  description = "EKS cluster name."
}

variable "kubernetes_version" {
  type        = string
  description = "EKS Kubernetes version."
  default     = null
}

variable "subnet_ids" {
  type        = list(string)
  description = "Subnets for the cluster ENIs and worker nodes (private subnets)."
}

variable "node_instance_types" {
  type        = list(string)
  description = "Instance types for the managed node group."
  default     = ["t3.medium"]
}

variable "node_desired_size" {
  type        = number
  description = "Desired worker node count."
}

variable "node_min_size" {
  type        = number
  description = "Minimum worker node count."
}

variable "node_max_size" {
  type        = number
  description = "Maximum worker node count."
}

variable "enabled_cluster_log_types" {
  type        = list(string)
  description = "EKS control-plane log types to enable, e.g. [\"api\", \"audit\"]."
  default     = []
}

variable "admin_principal_arns" {
  type        = list(string)
  description = "IAM user/role ARNs to grant full cluster-admin via an EKS access entry (AmazonEKSClusterAdminPolicy). Without this, only the IAM identity that ran 'terraform apply' can reach the cluster (EKS's implicit CONFIG_MAP creator mapping) — anyone else, including the AWS Console, gets Unauthorized."
  default     = []
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply."
  default     = {}
}
