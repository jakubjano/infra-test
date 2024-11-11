terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.53.0"
    }
  }

  required_version = ">= 1.8"
}
