variable "app_name" {
  type        = string
  description = "Application name"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID"
}

variable "database_subnet_group_name" {
  type        = string
  description = "Database subnet group name"
}

variable "database_subnets_cidr_blocks" {
  type        = list(string)
  description = "List of CIDR blocks of database subnets"
}

variable "database_min_acu" {
  type        = number
  description = <<EOT
  The minimum number of Aurora capacity units (ACUs) for a DB instance
  in an Aurora Serverless v2 cluster. You can specify ACU values in
  half-step increments, such as 8, 8.5, 9, and so on. The smallest
  value that you can use is 0.5.
  EOT
  default     = 0.5
}

variable "database_max_acu" {
  type        = number
  description = <<EOT
  The maximum number of Aurora capacity units (ACUs) for a DB instance
  in an Aurora Serverless v2 cluster. You can specify ACU values in
  half-step increments, such as 40, 40.5, 41, and so on. The largest
  value that you can use is 128.
  EOT
  default     = 1.0
}
