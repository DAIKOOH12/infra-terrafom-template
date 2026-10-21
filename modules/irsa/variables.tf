variable "name" {
  type        = string
  description = "IAM role name."
}

variable "oidc_provider_arn" {
  type        = string
  description = "ARN of the aws_iam_openid_connect_provider created for the EKS cluster (modules/eks output oidc_provider_arn)."
}

variable "oidc_issuer_host" {
  type        = string
  description = "EKS OIDC issuer URL with the https:// scheme stripped, e.g. oidc.eks.ap-southeast-1.amazonaws.com/id/XXXXXXXX (modules/eks output oidc_issuer_url, scheme removed)."
}

variable "namespace" {
  type        = string
  description = "Kubernetes namespace of the ServiceAccount allowed to assume this role."
}

variable "service_account_name" {
  type        = string
  description = "Kubernetes ServiceAccount name allowed to assume this role."
}

variable "policy_arns" {
  type        = list(string)
  description = "Existing managed/customer IAM policy ARNs to attach."
  default     = []
}

variable "inline_policy_json" {
  type        = string
  description = "Inline IAM policy document (JSON string) to attach. Leave null to skip."
  default     = null
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply."
  default     = {}
}
