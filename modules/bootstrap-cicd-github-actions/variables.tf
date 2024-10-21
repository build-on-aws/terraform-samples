variable "github_organization" {
  description = "(Required) Name of the GitHub organization"
  type        = string
}

variable "github_repository" {
  description = "(Required) The name of the GitHub repository to use"
  type        = string
}

variable "state_file_iam_policy_arn" {
  description = "(Required) ARN of IAM policy allowing access to the state file"
  type        = string
}

variable "aws_region" {
  description = "(Required) AWS region to use"
  type        = string
}

variable "github_actions_terraform_version" {
  description = "(Required) Version of terraform to use in GitHub Actions"
  type        = string
}

variable "override_repository_default_branch_name" {
  description = "Override the default branch name, defaults to main"
  type        = string
  default     = null
}

variable "override_terraform_source_dir" {
  description = "Override the directory in the repo where the terraform code is, defaults to terraform/ - please include trailing slash in override"
  type        = string
  default     = null
}

variable "override_aws_github_token_ssm_name" {
  description = "Override name of the AWS SSM location for the GitHub Token, defaults to /cicd/github_token"
  type        = string
  default     = null
}

variable "override_iam_role_name_apply" {
  description = "Override the IAM role name used by the GitHub Actions workflows for terraform apply, defaults to gh-tf-apply-<repo_name>"
  type        = string
  default     = null
}

variable "override_iam_policy_apply_arn" {
  description = "Override the IAM policy ARN used by the GitHub Actions workflows for terraform apply, defaults to built-in policy/AdministratorAccess"
  type        = string
  default     = null
}

variable "override_iam_role_name_plan" {
  description = "Override the IAM role name used by the GitHub Actions workflows for terraform plan, defaults to gh-tf-plan-<repo_name>"
  type        = string
  default     = null
}

variable "override_iam_policy_plan_arn" {
  description = "Override the IAM policy ARN used by the GitHub Actions workflows for terraform plan, defaults to built-in policy/ReadOnlyAccess"
  type        = string
  default     = null
}

variable "override_github_terraform_workflow_filename" {
  description = "Override the GitHub Actions terraform workflow filename, defaults to terraform.yml"
  type        = string
  default     = null
}

variable "override_aws_ssm_name_github_token" {
  description = "Name of the SSM parameter to store the GitHub token, defaults to /cicd/github_token"
  type        = string
  default     = null
}

variable "override_github_provider_version" {
  description = "Version of the GitHub provider to use, defaults to 6.0"
  type        = string
  default     = null
}

variable "override_aws_tags" {
  description = "Override tags to apply to AWS resources"
  type        = map(string)
  default     = null
}