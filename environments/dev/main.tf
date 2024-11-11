module "common" {
  source = "../../modules/common"

  app_name = var.app_name

  github_infra_repository_name = var.github_infra_repository_name
}

module "vpc" {
  source = "../../modules/vpc"

  app_name = var.app_name

  public_subnets   = local.public_subnets
  database_subnets = local.database_subnets
  private_subnets  = local.private_subnets
}

module "database" {
  source = "../../modules/database"

  app_name = var.app_name

  vpc_id                       = module.vpc.vpc_id
  database_subnet_group_name   = module.vpc.database_subnet_group_name
  database_subnets_cidr_blocks = module.vpc.database_subnets_cidr_blocks

  database_min_acu = var.db_min_acu
  database_max_acu = var.db_max_acu
}

module "service" {
  source = "../../modules/service"

  app_name    = var.app_name
  aws_region  = local.aws_region
  environment = local.environment

  vpc_id              = module.vpc.vpc_id
  vpc_private_subnets = module.vpc.private_subnets
  vpc_public_subnets  = module.vpc.public_subnets

  ecr_repository_url = var.ecr_repository_url

  api_image_version                  = var.api_image_version
  api_env_vars                       = var.api_env_vars
  firebase_credentials_ssm_parameter = var.firebase_credentials_ssm_parameter
  swagger_ui_credentials             = var.swagger_ui_credentials

  cloudwatch_retention_in_days = var.cloudwatch_retention_in_days

  ecs_min_instances = var.ecs_min_instances
  ecs_max_instances = var.ecs_max_instances
  ecs_task_cpu      = var.ecs_task_cpu
  ecs_task_memory   = var.ecs_task_memory

  database_cluster_endpoint                      = module.database.cluster_endpoint
  database_cluster_port                          = module.database.cluster_port
  database_cluster_master_username               = module.database.cluster_master_username
  database_cluster_database_name                 = module.database.cluster_database_name
  database_cluster_master_password_ssm_parameter = module.database.cluster_master_password_ssm_parameter

  depends_on = [module.database]
}

module "remote_access" {
  source = "../../modules/remote-access"

  create_bastion_host = var.create_bastion_host
  create_vpn          = var.create_vpn
  app_name            = var.app_name

  vpc_id                        = module.vpc.vpc_id
  vpc_cidr                      = module.vpc.vpc_cidr
  vpc_subnets                   = module.vpc.public_subnets
  bastion_host_public_subnet_id = module.vpc.public_subnets[0]
  vpn_server_certificate_arn    = var.vpn_server_certificate_arn
  rds_security_group_id         = module.database.rds_security_group_id
}
