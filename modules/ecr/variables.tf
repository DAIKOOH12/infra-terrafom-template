variable "name" {
  type        = string
  description = "ECR repository name."
}

variable "image_tag_mutability" {
  type        = string
  description = "MUTABLE or IMMUTABLE."
  default     = "MUTABLE"
}

variable "scan_on_push" {
  type        = bool
  description = "Scan images for vulnerabilities on push."
  default     = true
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply."
  default     = {}
}
