data "terraform_remote_state" "compute" {
  backend = "s3"

  config = {
    bucket = "eks-lab-tfstate-770880870430"
    key    = "layer3-compute-dev.tfstate"
    region = "ap-southeast-1"
  }
}
