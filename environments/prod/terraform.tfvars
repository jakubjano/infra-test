app_name = "Go API template"

github_infra_repository_name = "strvcom/backend-infra-template-aws-terraform"

api_image_version = "0.1.0"
api_env_vars = [
  {
    "name" : "CORS_ALLOWED_ORIGINS"
    "value" : "*"
  },
  {
    "name" : "LOG_LEVEL"
    "value" : "debug"
  },
]
firebase_credentials_ssm_parameter = "go-api-template-firebase-credentials"
swagger_ui_credentials = {
  ssm_parameter_name     = "go-api-template-swagger-ui-name"
  ssm_parameter_password = "go-api-template-swagger-ui-password"
}

ecr_repository_url = "889155520802.dkr.ecr.us-east-1.amazonaws.com/go-api-template"

db_min_acu = 0.5
db_max_acu = 1.0

ecs_min_instances = 1
ecs_max_instances = 2
ecs_task_cpu      = 512
ecs_task_memory   = 1024

create_bastion_host = false
create_vpn          = false
#vpn_server_certificate_arn = ""
