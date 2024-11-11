variable "app_name" {
  type        = string
  description = "Application name"
}

variable "public_subnets" {
  type        = list(string)
  description = "VPC public subnets"
}

variable "database_subnets" {
  type        = list(string)
  description = "VPC database subnets"
}

variable "private_subnets" {
  type        = list(string)
  description = "VPC private subnets"
}
