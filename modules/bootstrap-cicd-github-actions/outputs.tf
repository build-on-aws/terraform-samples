output "aws_github_oidc_arn" {
  value = aws_iam_openid_connect_provider.github.arn
}

output "github_organization" {
  value = var.github_organization
}

output "aws_ssm_name_github_token" {
  value = local.aws_ssm_name_github_token
}

output "github_provider" {
  value = local.github_provider
}