output "codebuild_project_tf_plan" {
  value = resource.aws_codebuild_project.terraform_plan
}

output "codebuild_project_tf_apply" {
  value = resource.aws_codebuild_project.terraform_apply
}