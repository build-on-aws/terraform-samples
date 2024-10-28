
variable "state_file_bucket_name" {
  description = "(Required) Name of the S3 bucket to store the state file"
  type        = string
}

variable "state_file_bucket_key" {
  description = "(Required) Key of the S3 bucket to store the state file"
  type        = string
  default     = "terraform-state"
}

variable "state_file_aws_region" {
  description = "(Required) AWS region of the S3 bucket to store the state file"
  type        = string
}

variable "aws_region" {
  description = "(Deprecated) Not used, leaving for backward compatibility"
  type        = string
  default     = null
}

variable "state_file_profile_name" {
  description = "(Optional) Name of the AWS profile to use for the state file S3 bucket"
  type        = string
  default     = null
}

variable "tf_additional_providers" {
  description = "(Optional) List of additional Terraform providers"
  type = list(object({
    name             = string
    provider_source  = string
    provider_version = string
  }))
  default = []
}

variable "override_state_lock_table_name" {
  description = "(Optional) Override name of the DynamoDB table to use for locking while updating, defaults to terraform-state-lock"
  type        = string
  default     = null
}

variable "override_aws_tags" {
  description = "(Optional) Override tags to apply to AWS resources"
  type        = map(string)
  default     = null
}

variable "override_kms_key_alias" {
  description = "(Optional) Override KMS key alias to use for state file encryption, defaults to alias/kms/s3"
  type        = string
  default     = null
}

variable "override_tf_version" {
  description = "(Optional) Override version of Terraform to use, defaults to 1.9.7 if not set"
  type        = string
  default     = null
}

variable "override_aws_provider_version" {
  description = "(Optional) Override version of AWS provider to use, defaults to 5.70.0 if not set"
  type        = string
  default     = null
}

variable "override_local_provider_version" {
  description = "(Optional) Override version of local provider to use, defaults to 2.5.2 if not set"
  type        = string
  default     = null
}
