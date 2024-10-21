## Terraform samples

Collection of examples of how to use Terraform with AWS.

List of modules:

| Module | Description|
|-|-|
|[bootstrap-aws-account](./modules/bootstrap-aws-account/)|Helps bootstrap a new AWS account to use Terraform by creating the resources needed to store the state file.|
|[bootstrap-cicd-aws-codebuild](./modules/bootstrap-cicd-aws-codebuild/)|Sets up a CI/CD pipeline for Terraform in a GitHub repo, with workflows to add the plan as a comment on pull requests, and apply changes when a PR is merged using AWS CodeBuild.|
|[bootstrap-cicd-github-actions](./modules/bootstrap-cicd-github-actions/)|Sets up a CI/CD pipeline for Terraform in a GitHub repo, with workflows to add the plan as a comment on pull requests, and apply changes when a PR is merged using GitHub Actions.|
|[bootstrap-cloudtrail](./modules/bootstrap-cloudtrail/)|Sets up a basic AWS CloudTrail configuration for the account.|
|[aws-billing-budget-notification](./modules/aws-billing-budget-notification/)|Sets up an AWS Budget with an email alert.|

## Security

See [CONTRIBUTING](CONTRIBUTING.md#security-issue-notifications) for more information.

## License

This library is licensed under the MIT-0 License. See the LICENSE file.
