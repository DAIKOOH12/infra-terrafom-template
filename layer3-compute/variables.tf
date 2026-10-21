variable "region" {
  type = string
}

variable "tags" {
  type = map(string)
}

variable "eks_name" {
  type = string
}

variable "eks_version" {
  type    = string
  default = null
}

variable "node_instance_type" {
  type = string
}

variable "node_desired_size" {
  type = number
}

variable "node_min_size" {
  type = number
}

variable "node_max_size" {
  type = number
}

variable "cluster_log_types" {
  type        = list(string)
  description = "EKS control-plane log types to enable. Leave empty to skip (no log group needed then)."
  default     = []
}

variable "admin_principal_arns" {
  type        = list(string)
  description = "IAM user/role ARNs to grant cluster-admin access (EKS access entry). Include your own console/CLI identity here or you'll get Unauthorized in the console or kubectl."
  default     = []
}
