variable "github_organization" {
  description = "(Required) Name of the GitHub organization"
  type        = string
}

variable "github_repository" {
  description = "(Required) The name of the GitHub repository to use"
  type        = string
}

variable "aws_region" {
  description = "(Required) AWS region to use"
  type        = string
}

variable "codebuild_terraform_version" {
  description = "(Required) Version of terraform to use in CodeBuild, only supply the version number, e.g. \"1.9.7\""
  type        = string
}

variable "override_repo_source_files_bucket_name" {
  description = "Override the S3 bucket name for the repo source file, defaults to src_<git_org>_<github_repo>"
  type        = string
  default     = null
}

variable "override_kms_key_alias" {
  description = "Override KMS key alias to use for state file encryption, defaults to alias/kms/s3"
  type        = string
  default     = null
}

variable "override_terraform_build_image_uri" {
  description = "Override the Docker image URI for the CodeBuild project for terraform build, defaults to public.ecr.aws/hashicorp/terraform:<var.codebuild_terraform_version>"
  type        = string
  default     = null
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

variable "override_iam_role_name_codebuild_apply" {
  description = "Override the IAM role name used by CodeBuild for terraform apply, defaults to gh-<repo_name>-tf-apply"
  type        = string
  default     = null
}

variable "override_iam_policy_apply_arn" {
  description = "Override the IAM policy ARN used by the CodeBuild for terraform apply, defaults to built-in policy/AdministratorAccess"
  type        = string
  default     = null
}

variable "override_iam_role_name_codebuild_plan" {
  description = "Override the IAM role name used by the CodeBuild for terraform plan, defaults to gh-<repo_name>-tf-plan"
  type        = string
  default     = null
}

variable "override_iam_policy_plan_arn" {
  description = "Override the IAM policy ARN used by the CodeBuild for terraform plan, defaults to built-in policy/ReadOnlyAccess"
  type        = string
  default     = null
}

variable "override_aws_ssm_name_github_token" {
  description = "Name of the SSM parameter to store the GitHub token, defaults to /cicd/github_token"
  type        = string
  default     = null
}

variable "override_aws_tags" {
  description = "Override tags to apply to AWS resources"
  type        = map(string)
  default     = null
}