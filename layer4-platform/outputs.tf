output "backend_secret_arn" {
  value = aws_secretsmanager_secret.backend_database_url.arn
}

output "backend_secrets_role_arn" {
  description = "Set this as nestjs/values.yaml externalSecret.irsaRoleArn."
  value       = module.backend_secrets_irsa.role_arn
}

output "frontend_parameter_names" {
  value = [for p in aws_ssm_parameter.frontend : p.name]
}

output "frontend_config_role_arn" {
  description = "Set this as nextjs/values.yaml externalSecret.irsaRoleArn."
  value       = module.frontend_config_irsa.role_arn
}

output "alb_controller_role_arn" {
  description = "Set this as apps/values.yaml aws-load-balancer-controller.serviceAccount.annotations['eks.amazonaws.com/role-arn']."
  value       = module.alb_controller_irsa.role_arn
}
