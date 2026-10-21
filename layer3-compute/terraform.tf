terraform {
  required_version = ">= 1.6"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }

  backend "s3" {
    bucket       = "eks-lab-tfstate-770880870430"
    key          = "layer3-compute-dev.tfstate"
    region       = "ap-southeast-1"
    use_lockfile = true
  }
}
