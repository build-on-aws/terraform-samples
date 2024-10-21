#--------------------------------------------#
# Using locals instead of hard-coding strings
#--------------------------------------------#
locals {
  terraform_source_dir                   = coalesce(var.override_terraform_source_dir, "terraform/")
  repository_default_branch_name         = coalesce(var.override_repository_default_branch_name, "main")
  github_provider_version                = coalesce(var.override_github_provider_version, "6.0")
  iam_role_name_apply                    = coalesce(var.override_iam_role_name_apply, "gh-tf-apply-${substr(var.github_repository, 0, 64 - length("gh-tf-apply-"))}")
  iam_role_name_plan                     = coalesce(var.override_iam_role_name_plan, "gh-tf-plan-${substr(var.github_repository, 0, 64 - length("gh-tf-apply-"))}")
  iam_policy_apply                       = coalesce(var.override_iam_policy_apply_arn, "arn:aws:iam::aws:policy/AdministratorAccess")
  iam_policy_plan                        = coalesce(var.override_iam_policy_plan_arn, "arn:aws:iam::aws:policy/ReadOnlyAccess")
  aws_ssm_name_github_token              = coalesce(var.override_aws_ssm_name_github_token, "/cicd/github_token")
  github_terraform_workflow_file         = coalesce(var.override_github_terraform_workflow_filename, "terraform.yml")
  github_env_var_name_iam_role_plan_arn  = "AWS_IAM_ROLE_PLAN"
  github_env_var_name_iam_role_apply_arn = "AWS_IAM_ROLE_APPLY"
  github_env_var_name_aws_region         = "AWS_REGION"
  github_env_var_name_terraform_version  = "TF_VERSION"
  github_env_var_name_github_token       = "GH_TOKEN"

  aws_tags = {
    GitHubRepo = "${var.github_organization}/${var.github_repository}"
    Module     = "build-on-aws/terraform-samples/modules/bootstrap-cicd-github-actions"
  }

  # https://github.blog/changelog/2023-06-27-github-actions-update-on-oidc-integration-with-aws/
  github_cert_thumbprint = [
    "6938fd4d98bab03faadb97b34396831e3780aea1",
    "1c58a3a8518e8759bf075b76b750d4f2df264fcd"
  ]

  github_provider = [
    {
      name             = "github"
      provider_source  = "integrations/github"
      provider_version = local.github_provider_version
    }
  ]
}

# Create the GitHub provider to use the GitHub token retrieved from SSM
resource "local_file" "tf_github_provider" {
  filename             = "${path.root}/provider-github.tf"
  directory_permission = "0666"
  file_permission      = "0666"
  content = templatefile("${path.module}/templates/provider-github.tf.tmpl", {
    github_organization = var.github_organization
  })
}

# # Set up access from GitHub into the account. The thumbprint for GitHub
# # certificate can be used from the post 
# # https://github.blog/changelog/2022-01-13-github-actions-update-on-oidc-based-deployments-to-aws/
# # or generated. 
resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  thumbprint_list = local.github_cert_thumbprint
  tags            = local.aws_tags
  client_id_list  = ["sts.amazonaws.com"]
}

#------------------------------------------------------------#
# IAM Role used to apply changes.
# Defaults to policy/AdministratorAccess, 
# but can be overridden to a custom policy
# by setting var.override_iam_policy_administrator_access_arn
#------------------------------------------------------------#

data "aws_iam_policy_document" "github_actions_write_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    # Condition to limit to default AWS OIDC audience
    # see: https://github.com/aws-actions/configure-aws-credentials?tab=readme-ov-file#oidc-audience
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    # Condition to limit to commits to the main branch
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values = [
        "repo:${var.github_organization}/${var.github_repository}:ref:refs/heads/${local.repository_default_branch_name}"
      ]
    }
  }
}

# Role to allow GitHub actions to use this AWS account
resource "aws_iam_role" "github_actions_apply" {
  name               = local.iam_role_name_apply
  assume_role_policy = data.aws_iam_policy_document.github_actions_write_assume_role_policy.json
  tags               = local.aws_tags
}

# Allow GitHub actions to create infrastructure
resource "aws_iam_role_policy_attachment" "github_actions_apply_policy" {
  role       = aws_iam_role.github_actions_apply.name
  policy_arn = local.iam_policy_apply
}

# Attach the state lock table access policy
resource "aws_iam_role_policy_attachment" "github_actions_apply_state_lock_policy" {
  role       = aws_iam_role.github_actions_apply.name
  policy_arn = var.state_file_iam_policy_arn
}

#------------------------------------------------------------#
# IAM Role used to plan changes.
# Defaults to policy/ReadOnly, 
# but can be overridden to a custom policy
# by setting var.override_iam_policy_read_only_arn
#------------------------------------------------------------#

data "aws_iam_policy_document" "github_actions_read_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    # Condition to limit to default AWS OIDC audience
    # see: https://github.com/aws-actions/configure-aws-credentials?tab=readme-ov-file#oidc-audience
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    # Condition to limit to pull requests
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values = [
        "repo:${var.github_organization}/${var.github_repository}:pull_request",
        "repo:${var.github_organization}/${var.github_repository}:ref/pull/*",
        "repo:${var.github_organization}/${var.github_repository}:ref:refs/heads/${local.repository_default_branch_name}"
      ]
    }
    # # Condition to limit to pull requests targeting 'main' branch
    # condition {
    #   test     = "StringEquals"
    #   variable = "token.actions.githubusercontent.com:ref"
    #   values = [
    #     "refs/heads/${var.repository_default_branch_name}" # Only allow for PRs targeting the 'main' branch
    #   ]
    # }
  }
}

# Role to allow GitHub actions to use this AWS account to run terraform plan
resource "aws_iam_role" "github_actions_plan" {
  name               = local.iam_role_name_plan
  assume_role_policy = data.aws_iam_policy_document.github_actions_read_assume_role_policy.json
  tags               = local.aws_tags
}

# Allow GitHub actions to create infrastructure
resource "aws_iam_role_policy_attachment" "github_actions_plan_policy" {
  role       = aws_iam_role.github_actions_plan.name
  policy_arn = local.iam_policy_plan
}

# Attach the state lock table access policy
resource "aws_iam_role_policy_attachment" "github_actions_plan_state_lock_policy" {
  role       = aws_iam_role.github_actions_plan.name
  policy_arn = var.state_file_iam_policy_arn
}

#---------------------------------------------------------#
# Create the GitHub Actions workflow file in the code repo
#---------------------------------------------------------#

resource "local_file" "github_actions_cicd_workflow" {
  filename = "${path.root}/../.github/workflows/${local.github_terraform_workflow_file}"
  content = templatefile("${path.module}/templates/github_actions_workflow.yml.tmpl", {
    terraform_source_dir = local.terraform_source_dir
    aws_region           = var.aws_region
    github_organization  = var.github_organization
    github_repository    = var.github_repository
  })
}

data "aws_ssm_parameter" "github_token" {
  name = local.aws_ssm_name_github_token
}

resource "github_actions_secret" "github_cicd_token" {
  repository  = var.github_repository
  secret_name = local.github_env_var_name_github_token

  # You can replace this with encrypted_value - this requires 
  # encrypting the value and storing the encrypted string in SSM,
  # see https://docs.github.com/en/rest/guides/encrypting-secrets-for-the-rest-api
  plaintext_value = data.aws_ssm_parameter.github_token.value
}

resource "github_actions_variable" "tf_version" {
  repository    = var.github_repository
  variable_name = local.github_env_var_name_terraform_version
  value         = var.github_actions_terraform_version
}

resource "github_actions_secret" "iam_policy_apply_changes_name" {
  repository      = var.github_repository
  secret_name     = local.github_env_var_name_iam_role_apply_arn
  plaintext_value = aws_iam_role.github_actions_apply.arn
}

resource "github_actions_secret" "iam_role_plan_changes_name" {
  repository      = var.github_repository
  secret_name     = local.github_env_var_name_iam_role_plan_arn
  plaintext_value = aws_iam_role.github_actions_plan.arn
}

resource "github_actions_variable" "aws_region" {
  repository    = var.github_repository
  variable_name = local.github_env_var_name_aws_region
  value         = var.aws_region
}

