data "aws_caller_identity" "current" {}

locals {
  cluster_name      = data.terraform_remote_state.compute.outputs.cluster_name
  oidc_provider_arn = data.terraform_remote_state.compute.outputs.oidc_provider_arn
  # EKS access-entry APIs return the issuer with the https:// scheme; the IAM
  # trust-policy condition keys need it stripped (see modules/irsa).
  oidc_issuer_host = replace(data.terraform_remote_state.compute.outputs.oidc_issuer_url, "https://", "")
  account_id       = data.aws_caller_identity.current.account_id
}

# --- Backend: AWS Secrets Manager -------------------------------------------

# Only the container (name + shape) is Terraform-managed. The value is set out
# of band so a real DATABASE_URL never sits in tfvars/state history:
#   aws secretsmanager put-secret-value --secret-id <backend_secret_name> \
#     --secret-string '{"DATABASE_URL":"postgres://..."}'
resource "aws_secretsmanager_secret" "backend_database_url" {
  name = var.backend_secret_name
  tags = var.tags
}
 
module "backend_secrets_irsa" {
  source               = "../modules/irsa"
  name                 = "${local.cluster_name}-backend-secrets"
  oidc_provider_arn    = local.oidc_provider_arn
  oidc_issuer_host     = local.oidc_issuer_host
  namespace            = var.backend_namespace
  service_account_name = var.backend_service_account_name
  tags                 = var.tags

  inline_policy_json = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "secretsmanager:GetSecretValue"
      Resource = aws_secretsmanager_secret.backend_database_url.arn
    }]
  })
}

# --- Frontend: SSM Parameter Store ------------------------------------------

resource "aws_ssm_parameter" "frontend" {
  for_each = var.frontend_parameters
  name     = "${trimsuffix(var.frontend_parameter_path, "/")}/${each.key}"
  type     = "String"
  value    = each.value
  tags     = var.tags
}

module "frontend_config_irsa" {
  source               = "../modules/irsa"
  name                 = "${local.cluster_name}-frontend-config"
  oidc_provider_arn    = local.oidc_provider_arn
  oidc_issuer_host     = local.oidc_issuer_host
  namespace            = var.frontend_namespace
  service_account_name = var.frontend_service_account_name
  tags                 = var.tags

  inline_policy_json = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "ssm:GetParameter",
        "ssm:GetParameters",
        "ssm:GetParametersByPath",
      ]
      Resource = "arn:aws:ssm:${var.region}:${local.account_id}:parameter${var.frontend_parameter_path}*"
    }]
  })
}

# --- AWS Load Balancer Controller -------------------------------------------

# Official policy from the aws-load-balancer-controller project — do not
# hand-edit; re-download from
# https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/main/docs/install/iam_policy.json
# when bumping the chart version in apps/values.yaml.
resource "aws_iam_policy" "alb_controller" {
  name   = "${local.cluster_name}-alb-controller"
  policy = file("${path.module}/files/alb_iam_policy.json")
  tags   = var.tags
}

module "alb_controller_irsa" {
  source               = "../modules/irsa"
  name                 = "${local.cluster_name}-alb-controller"
  oidc_provider_arn    = local.oidc_provider_arn
  oidc_issuer_host     = local.oidc_issuer_host
  namespace            = var.alb_controller_namespace
  service_account_name = var.alb_controller_service_account_name
  policy_arns          = [aws_iam_policy.alb_controller.arn]
  tags                 = var.tags
}
