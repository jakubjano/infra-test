terraform {
  backend "s3" {
    bucket = "dev-template-terraform-805382315593-us-east-1"
    key    = "terraform.tfstate"
    region = "us-east-1"

    dynamodb_table = "dev-template-terraform-805382315593-us-east-1"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.53.0"
    }
  }

  required_version = ">= 1.8"
}

provider "aws" {
  region = local.aws_region

  default_tags {
    tags = {
      AppName     = var.app_name
      Environment = local.environment
    }
  }
}
