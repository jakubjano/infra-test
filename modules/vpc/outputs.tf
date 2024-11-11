output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "vpc_cidr" {
  description = "VPC network CIDR"
  value       = module.vpc.vpc_cidr_block
}

output "public_subnets" {
  description = "Public subnets"
  value       = module.vpc.public_subnets
}

output "private_subnets" {
  description = "Private subnets"
  value       = module.vpc.private_subnets
}

output "database_subnet_group_name" {
  description = "Database subnet group name"
  value       = module.vpc.database_subnet_group_name
}

output "database_subnets_cidr_blocks" {
  description = "List of CIDR blocks of database subnets"
  value       = module.vpc.database_subnets_cidr_blocks
}
