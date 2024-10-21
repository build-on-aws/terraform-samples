variable "aws_region" {
  description = "(Required) Primary AWS region to create resources in"
  type        = string
}

variable "cloudtrail_bucket_name" {
  description = "(Required) Name of the S3 bucket to store the CloudTrail logs in"
  type        = string
}

variable "cloudtrail_name" {
  description = "(Required) Name of the CloudTrail trail"
  type        = string
}

variable "override_tf_version" {
  description = "Override version of Terraform to use, defaults to 1.9.7 if not set"
  type        = string
  default     = null
}

variable "override_aws_tags" {
  description = "Override tags to apply to AWS resources"
  type        = map(string)
  default     = null
}