terraform {
  required_version = ">= 1.6"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket       = "eks-lab-tfstate-770880870430"
    key          = "layer1-network-dev.tfstate"
    region       = "ap-southeast-1"
    use_lockfile = true
  }
}
