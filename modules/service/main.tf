##############################################################
# Roles
##############################################################

# For both ECS task role and ECS task execution role.
data "aws_iam_policy_document" "assume_role_policy_by_ecs" {
  statement {
    sid     = "AllowAssumeRoleForECSTask"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "ecs_task_execution_common" {
  statement {
    sid    = "AllowDownloadDockerImage"
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "AllowStoreLogs"
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "ecs_task_execution_common" {
  name   = "${local.api_name}-ecs-task-execution-common"
  policy = data.aws_iam_policy_document.ecs_task_execution_common.json
}

data "aws_iam_policy_document" "ecs_task_execution_api" {
  statement {
    effect = "Allow"
    actions = [
      "ssm:GetParameters"
    ]
    resources = [
      data.aws_ssm_parameter.database_cluster_master_password.arn,
      data.aws_ssm_parameter.firebase_credentials.arn,
      data.aws_ssm_parameter.swagger_ui_name.arn,
      data.aws_ssm_parameter.swagger_ui_password.arn
    ]
  }
}

resource "aws_iam_policy" "ecs_task_execution_api" {
  name   = "${local.api_name}-ecs-task-execution"
  policy = data.aws_iam_policy_document.ecs_task_execution_api.json
}

resource "aws_iam_role" "ecs_task_execution_api" {
  name               = "${local.api_name}-ecs-task-execution"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy_by_ecs.json
  managed_policy_arns = [
    aws_iam_policy.ecs_task_execution_common.arn,
    aws_iam_policy.ecs_task_execution_api.arn
  ]
}

# This policy is actually not needed for the template. It's here
# just to provide an example how to add policies for the ECS task.
data "aws_iam_policy_document" "ecs_task_api" {
  statement {
    sid       = "AllowAllS3Operations"
    effect    = "Allow"
    actions   = ["s3:*"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "ecs_task_api" {
  name   = "${local.api_name}-ecs-task"
  policy = data.aws_iam_policy_document.ecs_task_api.json
}

# Append policies to this ECS task role for S3, DynamoDB, SNS or whatever your application needs.
resource "aws_iam_role" "ecs_task_api" {
  name               = "${local.api_name}-ecs-task"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy_by_ecs.json
  managed_policy_arns = [
    aws_iam_policy.ecs_task_api.arn
  ]
}

##############################################################
# SSM Params
##############################################################

data "aws_ssm_parameter" "database_cluster_master_password" {
  name = var.database_cluster_master_password_ssm_parameter
}

data "aws_ssm_parameter" "firebase_credentials" {
  name = var.firebase_credentials_ssm_parameter
}

data "aws_ssm_parameter" "swagger_ui_name" {
  name = var.swagger_ui_credentials.ssm_parameter_name
}

data "aws_ssm_parameter" "swagger_ui_password" {
  name = var.swagger_ui_credentials.ssm_parameter_password
}

##############################################################
# ECS
##############################################################

resource "aws_ecs_cluster" "this" {
  name = local.app_name_parsed

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_security_group" "service" {
  name        = "${local.api_name}-service"
  description = "Allows incoming traffic from load balancer"

  vpc_id = var.vpc_id

  ingress {
    description     = "Allows ingress traffic from load balancer"
    from_port       = 0
    to_port         = 0
    protocol        = "all"
    security_groups = [aws_security_group.lb.id]
  }

  egress {
    description      = "Allows all egress traffic"
    from_port        = 0
    to_port          = 0
    protocol         = "all"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_cloudwatch_log_group" "api" {
  name = "ecs-${local.api_name}"

  retention_in_days = var.cloudwatch_retention_in_days
}

resource "aws_ecs_task_definition" "api" {
  family = local.api_name

  container_definitions = jsonencode([
    {
      name      = local.api_name
      image     = "${var.ecr_repository_url}:${var.api_image_version}"
      essential = true

      environment = concat(local.api_static_env_vars, var.api_env_vars, [
        {
          name : "ENVIRONMENT"
          value : var.environment
        },
        {
          name : "DATABASE_HOST"
          value : var.database_cluster_endpoint
        },
        {
          name : "DATABASE_PORT"
          value : tostring(var.database_cluster_port)
        },
        {
          name : "DATABASE_USERNAME"
          value : var.database_cluster_master_username
        },
        {
          name : "DATABASE_DB_NAME"
          value : var.database_cluster_database_name
        }
      ])

      secrets = [
        {
          name : "DATABASE_PASSWORD"
          valueFrom : data.aws_ssm_parameter.database_cluster_master_password.arn
        },
        {
          name : "FIREBASE_CREDENTIALS"
          valueFrom : data.aws_ssm_parameter.firebase_credentials.arn
        },
        {
          name : "SWAGGER_UI_NAME",
          valueFrom : data.aws_ssm_parameter.swagger_ui_name.arn
        },
        {
          name : "SWAGGER_UI_PASSWORD"
          valueFrom : data.aws_ssm_parameter.swagger_ui_password.arn
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-region        = var.aws_region
          awslogs-group         = aws_cloudwatch_log_group.api.id
          awslogs-stream-prefix = local.app_name_parsed
        }
      }

      portMappings = [
        {
          containerPort = 8080
          protocol      = "tcp"
        }
      ]
    }
  ])

  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"

  cpu    = var.ecs_task_cpu
  memory = var.ecs_task_memory

  execution_role_arn = aws_iam_role.ecs_task_execution_api.arn
  task_role_arn      = aws_iam_role.ecs_task_api.arn
}

data "aws_ecs_task_definition" "api" {
  task_definition = aws_ecs_task_definition.api.family
}

resource "aws_ecs_service" "api" {
  name                = local.api_name
  cluster             = aws_ecs_cluster.this.id
  task_definition     = data.aws_ecs_task_definition.api.id
  launch_type         = "FARGATE"
  scheduling_strategy = "REPLICA"
  desired_count       = var.ecs_min_instances

  network_configuration {
    subnets          = var.vpc_private_subnets
    assign_public_ip = false
    security_groups = [
      aws_security_group.service.id,
    ]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.api.arn
    container_name   = local.api_name
    container_port   = 8080
  }

  depends_on = [aws_lb_listener.this]
}

resource "aws_appautoscaling_target" "api" {
  max_capacity       = var.ecs_max_instances
  min_capacity       = var.ecs_min_instances
  resource_id        = "service/${aws_ecs_cluster.this.name}/${aws_ecs_service.api.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "ecs_policy_api_memory" {
  name               = "${local.api_name}-memory-autoscaling"
  resource_id        = aws_appautoscaling_target.api.resource_id
  policy_type        = "TargetTrackingScaling"
  scalable_dimension = aws_appautoscaling_target.api.scalable_dimension
  service_namespace  = aws_appautoscaling_target.api.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }

    target_value       = 70
    scale_in_cooldown  = 60
    scale_out_cooldown = 60
  }
}

resource "aws_appautoscaling_policy" "ecs_policy_api_cpu" {
  name               = "${local.api_name}-cpu-autoscaling"
  resource_id        = aws_appautoscaling_target.api.resource_id
  policy_type        = "TargetTrackingScaling"
  scalable_dimension = aws_appautoscaling_target.api.scalable_dimension
  service_namespace  = aws_appautoscaling_target.api.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }

    target_value       = 70
    scale_in_cooldown  = 60
    scale_out_cooldown = 60
  }
}

##############################################################
# Load balancer
##############################################################

resource "aws_lb" "this" {
  name                       = local.app_name_parsed
  internal                   = false
  load_balancer_type         = "application"
  subnets                    = var.vpc_public_subnets
  security_groups            = [aws_security_group.lb.id]
  drop_invalid_header_fields = true
}

resource "aws_security_group" "lb" {
  name        = "${local.app_name_parsed}-lb"
  description = "Allows incoming connections"

  vpc_id = var.vpc_id

  ingress {
    description      = "Allows all HTTP ingress traffic"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    description      = "Allows all egress traffic"
    from_port        = 0
    to_port          = 0
    protocol         = "all"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_lb_target_group" "api" {
  name        = local.app_name_parsed
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id

  health_check {
    protocol            = "HTTP"
    matcher             = "204"
    path                = "/ping"
    healthy_threshold   = "2"
    unhealthy_threshold = "2"
    timeout             = "5"
    interval            = "30"
  }
}

resource "aws_lb_listener" "this" {
  load_balancer_arn = aws_lb.this.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Resource not found"
      status_code  = "404"
    }
  }
}

resource "aws_lb_listener_rule" "api" {
  listener_arn = aws_lb_listener.this.arn
  priority     = 1

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api.arn
  }

  condition {
    path_pattern {
      values = ["/*"]
    }
  }
}
