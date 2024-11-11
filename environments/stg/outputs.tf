output "bastion_host_private_key_openssh" {
  description = "Private PEM key for bastion host"
  value       = module.remote_access.bastion_host_private_key_openssh
  sensitive   = true
}

output "bastion_host_dns_name" {
  description = "Bastion host DNS name"
  value       = module.remote_access.bastion_host_dns_name
}

output "database_cluster_endpoint" {
  description = "Database cluster endpoint URL"
  value       = module.database.cluster_endpoint
}

output "ecs_load_balancer_dns_name" {
  description = "ECS load balancer DNS name"
  value       = module.service.ecs_load_balancer_dns_name
}
