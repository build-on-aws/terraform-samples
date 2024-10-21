variable "budget_email_address" {
  description = "(Required) Email address to send budget notifications to"
  type        = string
}

variable "budget_alert_currency" {
  description = "(Required) Currency to use for budget alert mails, defaults to USD"
  type        = string
  default     = "USD"
}

variable "budget_alert_amount" {
  description = "(Required) Budget amount for the alert, defaults to USD 10"
  type        = number
  default     = 10
}

variable "budget_alert_threshold_percentage" {
  description = "(Required) Budget alert threshold percentage to trigger the alert, defaults to 75"
  type        = number
  default     = 75
}

variable "override_aws_tags" {
  description = "Override tags to apply to AWS resources"
  type        = map(string)
  default     = null
}