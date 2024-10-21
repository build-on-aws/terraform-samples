output "state_file_iam_policy_arn" {
  value = aws_iam_policy.state_file_access_iam_policy.arn
}

output "aws_region_for_resources" {
  value = var.aws_region
}