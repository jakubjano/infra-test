##############################################################
# general variables
##############################################################

variable "app_name" {
  type        = string
  description = "Application name"
}

##############################################################
# Module common
##############################################################

variable "github_infra_repository_name" {
  type        = string
  description = "GitHub infra repository name"
}

##############################################################
# Module database
##############################################################

variable "db_min_acu" {
  type        = number
  description = <<EOT
  The minimum number of Aurora capacity units (ACUs) for a DB instance
  in an Aurora Serverless v2 cluster. You can specify ACU values in
  half-step increments, such as 8, 8.5, 9, and so on. The smallest
  value that you can use is 0.5.
  EOT
  default     = 0.5
}

variable "db_max_acu" {
  type        = number
  description = <<EOT
  The maximum number of Aurora capacity units (ACUs) for a DB instance
  in an Aurora Serverless v2 cluster. You can specify ACU values in
  half-step increments, such as 40, 40.5, 41, and so on. The largest
  value that you can use is 128.
  EOT
  default     = 1.0
}

##############################################################
# Module service
##############################################################

variable "api_image_version" {
  type        = string
  description = "Service docker image version"
}

variable "api_env_vars" {
  type = list(object({
    name  = string
    value = string
  }))
  description = "Environment variables for API ECS service"
}

variable "firebase_credentials_ssm_parameter" {
  type        = string
  description = "SSM parameter for Firebase credentials"
}

variable "swagger_ui_credentials" {
  description = "SSM parameters (name and password) for Swagger UI"
  type = object({
    ssm_parameter_name     = string
    ssm_parameter_password = string
  })
}

variable "ecr_repository_url" {
  type        = string
  description = "ECR repository URL"
}

variable "cloudwatch_retention_in_days" {
  type        = number
  description = "CloudWatch logs retention"
  default     = 3
}

variable "ecs_min_instances" {
  type        = number
  description = "Minimum instance count of the ECS service"
  default     = 1
}

variable "ecs_max_instances" {
  type        = number
  description = "Maximum instance count of the ECS service"
  default     = 2
}

variable "ecs_task_cpu" {
  type        = number
  description = "Hard limit of task CPU. 1024 == 1 vCPU"
  default     = 512
}

variable "ecs_task_memory" {
  type        = number
  description = "Hard limit of task memory. 1024 == 1 GiB"
  default     = 1024
}

##############################################################
# Module remote-access
##############################################################

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

variable "vpn_server_certificate_arn" {
  type        = string
  description = "Certificate for VPN server"
  default     = null
}
