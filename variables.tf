variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-1"
}

variable "environment" {
  description = "Environment tag"
  type        = string
  default     = "dev"
}

variable "budget_amount" {
  description = "Monthly budget amount in USD"
  type        = string
  default     = "0.10"
}

variable "notification_email" {
  description = "Email for budget notifications"
  type        = string
  default     = "your_email@domain.com"
}
