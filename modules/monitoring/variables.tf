variable "enabled" {
  type        = bool
  description = "Whether to create the log group."
  default     = true
}

variable "cluster_name" {
  type        = string
  description = "EKS cluster name. The log group name must be exactly /aws/eks/<cluster_name>/cluster for EKS control-plane logging to write into it."
}

variable "retention_in_days" {
  type        = number
  description = "CloudWatch log retention."
  default     = 30
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply."
  default     = {}
}
