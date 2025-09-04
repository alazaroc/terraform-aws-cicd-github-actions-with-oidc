terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }

  backend "s3" {
    bucket       = "terraform-tfstate-playingaws-poc"     # Update it
    key          = "poc/terraform-github-actions.tfstate" # Update it
    region       = "eu-west-1"                            # Update it
    encrypt      = true
    use_lockfile = true # S3 native block
  }
}

provider "aws" {
  region = var.aws_region
}

# Suffix to avoid duplicated names
resource "random_id" "budget_suffix" {
  byte_length = 2 # 4 characters hex (e.g. 'a1b2')
}

resource "aws_budgets_budget" "zero_spend_budget" {
  name         = "ZeroSpendBudget-${random_id.budget_suffix.hex}"
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
