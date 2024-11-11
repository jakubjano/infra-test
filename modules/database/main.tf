##############################################################
# Database
##############################################################

resource "random_password" "rds_password" {
  length  = 16
  special = false
}

resource "aws_ssm_parameter" "rds_cluster_config" {
  name        = "${local.app_name_parsed}-rds-cluster-config"
  type        = "String"
  description = "Values needed to build DB DSN except for the password"

  value = jsonencode({
    "host"     = module.aurora_cluster.cluster_endpoint
    "port"     = module.aurora_cluster.cluster_port
    "username" = module.aurora_cluster.cluster_master_username
    "db_name"  = module.aurora_cluster.cluster_database_name
  })
}

resource "aws_ssm_parameter" "rds_cluster_password" {
  name        = "${local.app_name_parsed}-rds-cluster-password"
  type        = "SecureString"
  description = "Password for the RDS cluster"

  value = random_password.rds_password.result
}

resource "aws_security_group" "rds" {
  name        = "${local.app_name_parsed}-rds"
  description = "Allows all database related ingress traffic"

  vpc_id = var.vpc_id

  ingress {
    description      = "Allows all database related ingress traffic"
    from_port        = 5432
    to_port          = 5432
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

data "aws_rds_engine_version" "postgresql" {
  engine  = "aurora-postgresql"
  version = "16.1"
}

module "aurora_cluster" {
  source  = "terraform-aws-modules/rds-aurora/aws"
  version = "9.4.0"

  name                        = "${local.app_name_parsed}-postgres"
  engine                      = data.aws_rds_engine_version.postgresql.engine
  engine_mode                 = "provisioned"
  engine_version              = data.aws_rds_engine_version.postgresql.version
  storage_encrypted           = true
  database_name               = replace(local.app_name_parsed, "-", "_")
  master_username             = replace(local.app_name_parsed, "-", "_")
  master_password             = random_password.rds_password.result
  manage_master_user_password = false

  vpc_id                 = var.vpc_id
  vpc_security_group_ids = [aws_security_group.rds.id]
  db_subnet_group_name   = var.database_subnet_group_name
  security_group_rules = {
    vpc_ingress = {
      cidr_blocks = var.database_subnets_cidr_blocks
    }
  }
  publicly_accessible = false

  apply_immediately                     = true
  skip_final_snapshot                   = true
  performance_insights_enabled          = true
  performance_insights_retention_period = 7

  instance_class = "db.serverless"
  serverlessv2_scaling_configuration = {
    min_capacity = var.database_min_acu
    max_capacity = var.database_max_acu
  }

  instances = {
    one = {}
    two = {}
  }
}
