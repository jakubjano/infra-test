output "cluster_endpoint" {
  description = "Cluster endpoint URL"
  value       = module.aurora_cluster.cluster_endpoint
}

output "cluster_port" {
  description = "Cluster port"
  value       = module.aurora_cluster.cluster_port
}

output "cluster_master_username" {
  description = "Cluster master user name"
  value       = module.aurora_cluster.cluster_master_username
}

output "cluster_database_name" {
  description = "Cluster database name"
  value       = module.aurora_cluster.cluster_database_name
}

output "cluster_master_password_ssm_parameter" {
  description = "Cluster master password"
  value       = aws_ssm_parameter.rds_cluster_password.name
}

output "rds_security_group_id" {
  description = "Database security group ID"
  value       = aws_security_group.rds.id
}
