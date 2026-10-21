variable "name" {
  type        = string
  description = "VPC name."
}

variable "cidr" {
  type        = string
  description = "VPC CIDR block."
}

variable "azs" {
  type        = list(string)
  description = "Availability zones to spread subnets across."
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "CIDR blocks for public subnets, one per AZ."
}

variable "private_subnet_cidrs" {
  type        = list(string)
  description = "CIDR blocks for private subnets (EKS nodes), one per AZ."
}

variable "cluster_name" {
  type        = string
  description = "EKS cluster name, used for the kubernetes.io/cluster/<name> subnet tags."
}

variable "enable_nat_gateway" {
  type        = bool
  description = "Create a single NAT gateway so private subnets reach the internet."
  default     = true
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply."
  default     = {}
}
