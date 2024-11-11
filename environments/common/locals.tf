locals {
  aws_region  = "us-east-1"
  environment = "common"

  app_name_parsed = replace(lower(var.app_name), " ", "-")
}
