#--------------------------------------------#
# Using locals instead of hard-coding strings
#--------------------------------------------#
locals {
  codebuild_image_uri              = coalesce(var.override_terraform_build_image_uri, "public.ecr.aws/hashicorp/terraform:${var.codebuild_terraform_version}")
  kms_key_alias                    = coalesce(var.override_kms_key_alias, "alias/aws/s3")
  codebuild_compute_type           = "BUILD_GENERAL1_SMALL"
  repo_source_files_bucket_name    = coalesce(var.override_repo_source_files_bucket_name, "src-${lower(var.github_organization)}-${lower(var.github_repository)}")
  terraform_source_dir             = coalesce(var.override_terraform_source_dir, "terraform/")
  repository_default_branch_name   = coalesce(var.override_repository_default_branch_name, "main")
  iam_role_name_codebuild_plan     = coalesce(var.override_iam_role_name_codebuild_plan, "gh-${substr(var.github_repository, 0, 64 - length("gh--tf-apply"))}-tf-plan")
  iam_role_name_codebuild_apply    = coalesce(var.override_iam_role_name_codebuild_apply, "gh-${substr(var.github_repository, 0, 64 - length("gh--tf-apply"))}-tf-apply")
  codebuild_project_name_plan      = "terraform-plan"
  codebuild_project_name_apply     = "terraform-apply"
  iam_policy_apply_arn             = coalesce(var.override_iam_policy_apply_arn, "arn:aws:iam::aws:policy/AdministratorAccess")
  iam_policy_plan_arn              = coalesce(var.override_iam_policy_plan_arn, "arn:aws:iam::aws:policy/ReadOnlyAccess")
  aws_ssm_name_github_token        = coalesce(var.override_aws_ssm_name_github_token, "/cicd/github_token")
  codebuild_spec_template_filename = "buildspec_terraform.yml.tmpl"
  github_token_env_var_name        = "GITHUB_TOKEN"

  aws_tags = {
    GitHubRepo = "${var.github_organization}/${var.github_repository}"
    Module     = "build-on-aws/terraform-samples/modules/bootstrap-cicd-aws-codebuild-codepipeline"
  }
}

data "aws_caller_identity" "current" {}

# Retrieve the GitHub token from AWS Systems Manager Parameter Store
data "aws_ssm_parameter" "github_token" {
  name = local.aws_ssm_name_github_token
}

# Set up access to GitHub using the token
resource "aws_codebuild_source_credential" "github" {
  auth_type   = "PERSONAL_ACCESS_TOKEN"
  server_type = "GITHUB"
  token       = data.aws_ssm_parameter.github_token.value
}

# S3 Bucket to store repo source code for builds
resource "aws_s3_bucket" "repo_source_files" {
  bucket = local.repo_source_files_bucket_name

  tags = local.aws_tags
}

# Ignore other ACLs to ensure bucket stays private
resource "aws_s3_bucket_public_access_block" "repo_source_files" {
  bucket = aws_s3_bucket.repo_source_files.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# Set ownership controls to bucket to prevent access from other AWS accounts
resource "aws_s3_bucket_ownership_controls" "repo_source_files" {
  bucket = aws_s3_bucket.repo_source_files.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

# Set bucket ACL to private
resource "aws_s3_bucket_acl" "repo_source_files" {
  depends_on = [
    aws_s3_bucket_ownership_controls.repo_source_files,
    aws_s3_bucket_public_access_block.repo_source_files,
  ]

  bucket = aws_s3_bucket.repo_source_files.id
  acl    = "private"
}

# Enable bucket versioning
resource "aws_s3_bucket_versioning" "repo_source_files" {
  bucket = aws_s3_bucket.repo_source_files.id

  versioning_configuration {
    status = "Enabled"
  }
}

data "aws_kms_alias" "s3" {
  name = local.kms_key_alias
}

# Encrypt bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "repo_source_files" {
  bucket = aws_s3_bucket.repo_source_files.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = data.aws_kms_alias.s3.target_key_arn
      sse_algorithm     = "aws:kms"
    }
  }
}

#-------------------------------------#
# IAM Roles and Policies for CodeBuild
#-------------------------------------#
data "aws_iam_policy_document" "codebuild_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "codebuild_cloudwatch_plan" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = [
      "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/codebuild/${local.codebuild_project_name_plan}:*",
    ]
  }
}

resource "aws_iam_role" "codebuild_plan_role" {
  name               = local.iam_role_name_codebuild_plan
  assume_role_policy = data.aws_iam_policy_document.codebuild_assume_role_policy.json
}

resource "aws_iam_role_policy_attachment" "plan_policy" {
  role       = aws_iam_role.codebuild_plan_role.name
  policy_arn = local.iam_policy_plan_arn
}

resource "aws_iam_policy" "plan_cloudwatch_policy" {
  name   = local.iam_role_name_codebuild_plan
  policy = data.aws_iam_policy_document.codebuild_cloudwatch_plan.json
}

resource "aws_iam_role_policy_attachment" "plan_cloudwatch_policy" {
  role       = aws_iam_role.codebuild_plan_role.name
  policy_arn = aws_iam_policy.plan_cloudwatch_policy.arn
}

# Attach the state lock table access policy
resource "aws_iam_role_policy_attachment" "plan_state_lock_policy" {
  role       = aws_iam_role.codebuild_plan_role.name
  policy_arn = var.state_file_iam_policy_arn
}

data "aws_iam_policy_document" "codebuild_cloudwatch_apply" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = [
      "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/codebuild/${local.codebuild_project_name_apply}:*",
    ]
  }
}

resource "aws_iam_role" "codebuild_apply_role" {
  name               = local.iam_role_name_codebuild_apply
  assume_role_policy = data.aws_iam_policy_document.codebuild_assume_role_policy.json
}

resource "aws_iam_role_policy_attachment" "apply_policy" {
  role       = aws_iam_role.codebuild_apply_role.name
  policy_arn = local.iam_policy_apply_arn
}

resource "aws_iam_policy" "apply_cloudwatch_policy" {
  name   = local.iam_role_name_codebuild_apply
  policy = data.aws_iam_policy_document.codebuild_cloudwatch_apply.json
}

resource "aws_iam_role_policy_attachment" "apply_cloudwatch_policy" {
  role       = aws_iam_role.codebuild_apply_role.name
  policy_arn = aws_iam_policy.apply_cloudwatch_policy.arn
}

# Attach the state lock table access policy
resource "aws_iam_role_policy_attachment" "apply_state_lock_policy" {
  role       = aws_iam_role.codebuild_apply_role.name
  policy_arn = var.state_file_iam_policy_arn
}

#----------------------------------------#
# CodeBuild projects and buildspec files
#----------------------------------------#
resource "aws_codebuild_project" "terraform_plan" {
  name         = local.codebuild_project_name_plan
  service_role = aws_iam_role.codebuild_plan_role.arn

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type    = local.codebuild_compute_type
    image           = local.codebuild_image_uri
    type            = "LINUX_CONTAINER"
    privileged_mode = false

    environment_variable {
      name  = local.github_token_env_var_name
      value = local.aws_ssm_name_github_token
      type  = "PARAMETER_STORE"
    }

    environment_variable {
      name  = "TF_WORKING_DIR"
      value = local.terraform_source_dir
    }

    environment_variable {
      name  = "GH_ORG_REPO"
      value = "${var.github_organization}/${var.github_repository}"
    }
  }

  source {
    type     = "GITHUB"
    location = "https://github.com/${var.github_organization}/${var.github_repository}"
    buildspec = templatefile("${path.module}/templates/${local.codebuild_spec_template_filename}",
      {
        is_pr_buildspec                = true
        terraform_source_dir           = local.terraform_source_dir
        repository_default_branch_name = local.repository_default_branch_name
      }
    )
  }

  cache {
    type     = "S3"
    location = aws_s3_bucket.repo_source_files.bucket
  }

  encryption_key = data.aws_kms_alias.s3.target_key_arn
}

resource "aws_codebuild_project" "terraform_apply" {
  name         = local.codebuild_project_name_apply
  service_role = aws_iam_role.codebuild_apply_role.arn

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type    = local.codebuild_compute_type
    image           = local.codebuild_image_uri
    type            = "LINUX_CONTAINER"
    privileged_mode = false

    environment_variable {
      name  = local.github_token_env_var_name
      value = local.aws_ssm_name_github_token
      type  = "PARAMETER_STORE"
    }

    environment_variable {
      name  = "TF_WORKING_DIR"
      value = local.terraform_source_dir
    }

    environment_variable {
      name  = "GH_ORG_REPO"
      value = "${var.github_organization}/${var.github_repository}"
    }
  }

  source {
    type     = "GITHUB"
    location = "https://github.com/${var.github_organization}/${var.github_repository}"
    buildspec = templatefile("${path.module}/templates/${local.codebuild_spec_template_filename}",
      {
        is_pr_buildspec                = false
        terraform_source_dir           = local.terraform_source_dir
        repository_default_branch_name = local.repository_default_branch_name
      }
    )
  }

  cache {
    type     = "S3"
    location = aws_s3_bucket.repo_source_files.bucket
  }

  encryption_key = data.aws_kms_alias.s3.target_key_arn
}

#--------------------------------------#
# Webhooks between CodeBuild and GitHub
#--------------------------------------#

resource "aws_codebuild_webhook" "pr_webhook" {
  project_name = aws_codebuild_project.terraform_plan.name

  filter_group {
    filter {
      type    = "EVENT"
      pattern = "PULL_REQUEST_CREATED,PULL_REQUEST_UPDATED,PULL_REQUEST_REOPENED"
    }

    filter {
      type    = "BASE_REF"
      pattern = local.repository_default_branch_name
    }
  }
}

resource "aws_codebuild_webhook" "main_branch_webhook" {
  project_name = aws_codebuild_project.terraform_apply.name

  filter_group {
    filter {
      type    = "EVENT"
      pattern = "PUSH"
    }

    filter {
      type    = "HEAD_REF"
      pattern = "refs/heads/${local.repository_default_branch_name}"
    }
  }
}
