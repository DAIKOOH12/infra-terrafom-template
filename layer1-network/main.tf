module "vpc" {
  source               = "../modules/vpc"
  name                 = var.vpc_name
  cidr                 = var.vpc_cidr
  azs                  = var.azs
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  cluster_name         = var.cluster_name
  tags                 = var.tags
}
