variable "region" {
  type = string
}

variable "tags" {
  type = map(string)
}

variable "ecr_name" {
  type = string
}

variable "ecr_image_tag_mutability" {
  type    = string
  default = "MUTABLE"
}

variable "ecr_scan_on_push" {
  type    = bool
  default = true
}

variable "enable_control_plane_logs" {
  type        = bool
  description = "Pre-create the CloudWatch log group for EKS control-plane logging."
  default     = true
}

variable "cluster_name" {
  type        = string
  description = "EKS cluster name (layer3-compute). Must match exactly — the log group name is derived from it."
}

variable "log_retention_days" {
  type    = number
  default = 30
}
