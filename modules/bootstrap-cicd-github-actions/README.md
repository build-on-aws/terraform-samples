## bootstrap-cicd-github-actions

Utility module to bootstrap creating a CI/CD pipeline for Terraform using GitHub Actions to provision AWS resources. Generates the Workflow file, and sets the variables / secrets on the workflow to allow running `terraform plan` on pull requests, and `terraform apply` on merges / commits to the `main` branch. IAM Role are limited to the type of trigger, PRs can only assume the IAM role with read-only access, and the `main` branch workflow can only assume the admin-level IAM role to create the infrastructure.

## License

This library is licensed under the MIT-0 License. See the LICENSE file.
