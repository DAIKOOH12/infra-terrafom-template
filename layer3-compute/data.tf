data "terraform_remote_state" "network" {
  backend = "s3"

  config = {
    bucket = "eks-lab-tfstate-770880870430"
    key    = "layer1-network-dev.tfstate"
    region = "ap-southeast-1"
  }
}

data "terraform_remote_state" "storage" {
  backend = "s3"

  config = {
    bucket = "eks-lab-tfstate-770880870430"
    key    = "layer2-storage-dev.tfstate"
    region = "ap-southeast-1"
  }
}
