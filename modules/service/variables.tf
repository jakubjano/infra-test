variable "app_name" {
  type        = string
  description = "Application name"
}

variable "aws_region" {
  type        = string
  description = "Deployment region"
}

variable "environment" {
  type        = string
  description = "Deployment environment"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID"
}

variable "vpc_public_subnets" {
  type        = list(string)
  description = "VPC public subnets"
}

variable "vpc_private_subnets" {
  type        = list(string)
  description = "VPC private subnets"
}

variable "ecr_repository_url" {
  type        = string
  description = "URL of ECR repository"
}

variable "api_image_version" {
  type        = string
  description = "Service docker image version"
}

variable "api_env_vars" {
  type = list(object({
    name  = string
    value = string
  }))
  description = "Environment variables for ECS service"
}

variable "firebase_credentials_ssm_parameter" {
  type        = string
  description = "SSM parameter for Firebase credentials"
}

variable "swagger_ui_credentials" {
  type = object({
    ssm_parameter_name     = string
    ssm_parameter_password = string
  })
  description = "SSM parameters (name and password) for Swagger UI"
}

variable "cloudwatch_retention_in_days" {
  type        = number
  description = "CloudWatch logs retention"
  default     = 3
}

variable "ecs_min_instances" {
  type        = number
  description = "Minimum instance count of the ECS service"
}

variable "ecs_max_instances" {
  type        = number
  description = "Maximum instance count of the ECS service"
}

variable "ecs_task_cpu" {
  type        = number
  description = "Hard limit of task CPU. 1024 == 1 vCPU"
}

variable "ecs_task_memory" {
  type        = number
  description = "Hard limit of task memory. 1024 == 1 GiB"
}

variable "database_cluster_endpoint" {
  type        = string
  description = "Database cluster endpoint URL"
}

variable "database_cluster_port" {
  type        = string
  description = "Database cluster port"
}

variable "database_cluster_master_username" {
  type        = string
  description = "Database cluster master user name"
}

variable "database_cluster_database_name" {
  type        = string
  description = "Database cluster database name"
}

variable "database_cluster_master_password_ssm_parameter" {
  type        = string
  description = "Database cluster master password SSM parameter"
}
