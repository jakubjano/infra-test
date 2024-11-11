variable "create_bastion_host" {
  type        = bool
  description = "Whether to create bastion host"
  default     = false
}

variable "create_vpn" {
  type        = bool
  description = "Whether to create VPN"
  default     = false
}

variable "app_name" {
  type        = string
  description = "Application name"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID"
}

variable "vpc_cidr" {
  type        = string
  description = "VPC network CIDR"
  default     = null
}

variable "vpc_subnets" {
  type        = list(string)
  description = "VPC subnets"
  default     = null
}

variable "bastion_host_public_subnet_id" {
  type        = string
  description = "Bastion host public subnet ID"
  default     = null
}

variable "vpn_server_certificate_arn" {
  type        = string
  description = "Certificate for VPN server"
  default     = null
}

variable "rds_security_group_id" {
  type        = string
  description = "Database security group ID"
  default     = null
}
