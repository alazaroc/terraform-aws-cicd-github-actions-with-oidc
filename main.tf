terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.0" }
  }
  backend "s3" {
    bucket         = "terraform-tfstate-playingaws-poc"     # Update it
    key            = "poc/terraform-github-actions.tfstate" # Update it
    region         = "eu-west-1"                            # Update it
    dynamodb_table = "terraform-lock"                       # Update it
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region
  default_tags {
    tags = {
      project     = "playingaws-terraform-github-actions"
      environment = var.environment
      managed-by  = "terraform"
    }
  }
}

resource "aws_budgets_budget" "zero_spend_budget" {
  name         = "ZeroSpendBudget"
  budget_type  = "COST"
  limit_amount = var.budget_amount
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  cost_types {
    include_credit  = false
    include_tax     = true
    include_support = true
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 0
    threshold_type             = "ABSOLUTE_VALUE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = [var.notification_email]
  }

  # Optional second alert:
  # notification {
  #   comparison_operator        = "GREATER_THAN"
  #   threshold                  = 0
  #   threshold_type             = "ABSOLUTE_VALUE"
  #   notification_type          = "FORECASTED"
  #   subscriber_email_addresses = [var.notification_email]
  # }
}
