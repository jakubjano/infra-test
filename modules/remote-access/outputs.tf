output "bastion_host_private_key_openssh" {
  description = "Private PEM key for bastion host"
  value       = module.key_pair.private_key_openssh
  sensitive   = true
}

output "bastion_host_dns_name" {
  description = "Bastion host DNS name"
  value       = module.ec2_instance.public_dns
}

output "bastion_host_security_group_id" {
  description = "Bastion host security group ID"
  value       = try(aws_security_group.bastion_host[0].id, null)
}

output "vpn_security_group_id" {
  description = "VPN security group ID"
  value       = try(aws_security_group.vpn[0].id, null)
}
