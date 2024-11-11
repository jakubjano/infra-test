locals {
  aws_region  = "us-east-1"
  environment = "prod"

  public_subnets   = ["10.0.1.0/24", "10.0.2.0/24"]
  database_subnets = ["10.0.3.0/24", "10.0.4.0/24"]
  private_subnets  = ["10.0.5.0/24", "10.0.6.0/24"]
}
