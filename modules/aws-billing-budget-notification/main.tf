#--------------------------------------------#
# Using locals instead of hard-coding strings
#--------------------------------------------#
locals {
  aws_tags = coalesce(var.override_aws_tags, {
    Name   = "tf-bootstrap",
    Module = "build-on-aws/terraform-samples/modules/bootstrap-aws-account",
  })
}

#-----------------------------------#
# Set up a Budget and Billing aleart
#-----------------------------------#
resource "aws_budgets_budget" "total_spend" {
  name         = "budget-monthly"
  budget_type  = "COST"
  limit_amount = var.budget_alert_amount
  limit_unit   = var.budget_alert_currency
  time_unit    = "MONTHLY"

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = var.budget_alert_threshold_percentage
    threshold_type             = "PERCENTAGE"
    notification_type          = "FORECASTED"
    subscriber_email_addresses = [var.budget_email_address]
  }

  tags = local.aws_tags
}