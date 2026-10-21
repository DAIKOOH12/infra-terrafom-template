module "ecr" {
  source               = "../modules/ecr"
  name                 = var.ecr_name
  image_tag_mutability = var.ecr_image_tag_mutability
  scan_on_push         = var.ecr_scan_on_push
  tags                 = var.tags
}

module "monitoring" {
  source            = "../modules/monitoring"
  enabled           = var.enable_control_plane_logs
  cluster_name      = var.cluster_name
  retention_in_days = var.log_retention_days
  tags              = var.tags
}
