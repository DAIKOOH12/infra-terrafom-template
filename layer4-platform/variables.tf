variable "region" {
  type = string
}

variable "tags" {
  type = map(string)
}

# --- Backend: AWS Secrets Manager -----------------------------------------

variable "backend_secret_name" {
  type        = string
  description = "AWS Secrets Manager secret name for the backend DATABASE_URL. Must match nestjs/values.yaml externalSecret.secretName."
}

variable "backend_namespace" {
  type    = string
  default = "be"
}

variable "backend_service_account_name" {
  type        = string
  description = "Must match nestjs/values.yaml externalSecret.serviceAccountName."
  default     = "backend-external-secrets"
}

# --- Frontend: SSM Parameter Store -----------------------------------------

variable "frontend_parameter_path" {
  type        = string
  description = "SSM Parameter Store path prefix. Must match nextjs/values.yaml externalSecret.parameterPath."
}

variable "frontend_parameters" {
  type        = map(string)
  description = "Parameters to create under frontend_parameter_path, key -> value (e.g. BACKEND_URL -> http://backend-nestjs.be.svc.cluster.local:3001). Not for secrets — use backend_secret_name/AWS Secrets Manager for those."
  default     = {}
}

variable "frontend_namespace" {
  type    = string
  default = "fe"
}

variable "frontend_service_account_name" {
  type        = string
  description = "Must match nextjs/values.yaml externalSecret.serviceAccountName."
  default     = "frontend-external-secrets"
}

# --- AWS Load Balancer Controller -------------------------------------------

variable "alb_controller_namespace" {
  type    = string
  default = "kube-system"
}

variable "alb_controller_service_account_name" {
  type        = string
  description = "Must match apps/values.yaml aws-load-balancer-controller.serviceAccount.name."
  default     = "aws-load-balancer-controller"
}
