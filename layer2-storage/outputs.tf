output "ecr_repository_url" {
  value = module.ecr.repository_url
}

output "ecr_repository_arn" {
  value = module.ecr.arn
}

output "log_group_name" {
  value = module.monitoring.log_group_name
}
