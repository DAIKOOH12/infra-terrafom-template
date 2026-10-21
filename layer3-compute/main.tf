locals {
  private_subnet_ids = data.terraform_remote_state.network.outputs.private_subnet_ids
  ecr_repository_url = data.terraform_remote_state.storage.outputs.ecr_repository_url
}

module "eks" {
  source                    = "../modules/eks"
  name                      = var.eks_name
  kubernetes_version        = var.eks_version
  subnet_ids                = local.private_subnet_ids
  node_instance_types       = [var.node_instance_type]
  node_desired_size         = var.node_desired_size
  node_min_size             = var.node_min_size
  node_max_size             = var.node_max_size
  enabled_cluster_log_types = var.cluster_log_types
  admin_principal_arns      = var.admin_principal_arns
  tags                      = var.tags
}

# Node role already carries AmazonEC2ContainerRegistryReadOnly (account-wide ECR
# pull), so no extra per-repository policy is needed to pull from
# local.ecr_repository_url — kept here only so it's visible/wired for later use.
