variable "aws_dev_account_id" {
  type        = string
  description = "AWS dev account ID"
}

variable "aws_stg_account_id" {
  type        = string
  description = "AWS stg account ID"
}

variable "aws_prod_account_id" {
  type        = string
  description = "AWS prod account ID"
}

variable "github_api_repository_name" {
  type        = string
  description = "GitHub API repository name"
}

variable "github_infra_repository_name" {
  type        = string
  description = "GitHub infra repository name"
}

variable "app_name" {
  type        = string
  description = "Application name"
}
