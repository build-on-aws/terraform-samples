## bootstrap-aws-account

Sets up the required resources for Terraform to use Amazon S3 as a backend. Will create the following resources:

1. **S3 bucket:** stores the state file, encrypted with KMS, and with versioning enabled
2. **DynamoDB table:** state file locking table
3. **terraform.tf:** local file with the S3 backend configuration values specified
4. **providers.tf:** defines the versions for Terraform, AWS, and Local provider to use

## Minimum configuration

To use the module, the following needs to be specified:

```terraform
module "bootstrap" {
    source = "github.com/build-on-aws/terraform-samples//modules/bootstrap-aws-account"

    state_file_aws_region  = "region-for-state-file-bucket"
    state_file_bucket_name = "name-for-the-state-file-bucket"
}
```

## Full configuration

|Variable|Type|Details|
|-|-|-|
|state_file_profile_name|`string`|AWS Profile to use for credentials instead of the default one|
|override_state_lock_table_name|`string`|Default value is `terraform-state-lock`, allows setting a different value.|
|override_aws_tags|`string`|Default value is `{Name   = "tf-bootstrap", Module = "build-on-aws/terraform-samples/modules/bootstrap-aws-account",}`, allows setting a different tags.|
|override_kms_key_alias|`string`|Default value is `alias/aws/s3`, allows setting a different key alias to use.|
|override_tf_version|`string`|Default value is `1.9.7`, allows setting a different value.|
|override_local_provider_version|`string`|Default value is `null`, allows setting a different value.|
|tf_additional_providers|`list(object({name = string provider_source  = string provider_version = string}))`|Default value is `[]`, allows adding additional providers to add to the generated `providers.tf` file.|

## License

This library is licensed under the MIT-0 License. See the LICENSE file.
