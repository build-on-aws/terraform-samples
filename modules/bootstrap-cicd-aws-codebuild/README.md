## bootstrap-cicd-aws-codebuild

Creates the basic infrastructure for a CI/CD pipeline using a GitHub repository. Creates:

1. **IAM Roles:** One role with read-only IAM policy allowing `terraform plan` to be run, and a 2nd role with an admin policy allowing `terraform apply` to be run.
2. **CodeBuild:** Creates 2 CodeBuild projects, one for `terraform plan` using a read-only IAM role, and a 2nd for `terraform apply` using an IAM role with admin permissions.
3. **Webhooks**: Webhooks to start the respective CodeBuild projects on pull requests, or PR merges / commits to the `main` branch.

### Usage

Requires a [GitHub PAT](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens) with the following permissions on the repositories to add the build projects for:

1. **Code**: Read-only - read the code to run terraform
2. **Pull Requests**: Read and Write - allows posting a summary of changes / errors on PRs
3. **Webhooks**: Read and Write - create the webhooks to trigger the CodeBuild jobs

The module uses the location `/cicd/github_token` in SSM Parameter Store as the default location, to store the PAT for this module, you can use the following command:

```bash
aws ssm put-parameter \
    --name "/cicd/github_token" \
    --value "your PAT value" \
    --type "SecureString" \
    --overwrite
```

## License

This library is licensed under the MIT-0 License. See the LICENSE file.
