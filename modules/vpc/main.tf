module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.8.1"

  name = local.app_name_parsed
  cidr = "10.0.0.0/16"
  azs  = ["us-east-1a", "us-east-1b"]

  public_subnets   = var.public_subnets
  database_subnets = var.database_subnets
  private_subnets  = var.private_subnets

  enable_nat_gateway = true
}
