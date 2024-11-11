##############################################################
# OIDC
##############################################################

module "iam_github_oidc_provider" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-github-oidc-provider"
  version = "5.39.1"
}

module "iam_github_oidc_role_cicd" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-github-oidc-role"
  version = "5.39.1"

  name        = "${local.app_name_parsed}-github-actions-cicd"
  description = "Administrator access for CI/CD"

  subjects = ["${var.github_infra_repository_name}:*"]
  policies = {
    AdministratorAccess = "arn:aws:iam::aws:policy/AdministratorAccess"
  }
}

##############################################################
# ECR
##############################################################

resource "aws_ecr_repository" "this" {
  name = local.app_name_parsed

  image_tag_mutability = "IMMUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }
}

data "aws_iam_policy_document" "ecr_image_puller" {
  statement {
    sid    = "Image puller"
    effect = "Allow"
    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${var.aws_dev_account_id}:root",
        "arn:aws:iam::${var.aws_stg_account_id}:root",
        "arn:aws:iam::${var.aws_prod_account_id}:root",
      ]
    }
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
    ]
  }
}

resource "aws_ecr_repository_policy" "this" {
  repository = aws_ecr_repository.this.name
  policy     = data.aws_iam_policy_document.ecr_image_puller.json
}

data "aws_iam_policy_document" "ecr_image_pusher" {
  statement {
    sid    = "AllowPushToECRRepository"
    effect = "Allow"
    actions = [
      "ecr:CompleteLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:InitiateLayerUpload",
      "ecr:BatchCheckLayerAvailability",
      "ecr:PutImage",
    ]
    resources = [aws_ecr_repository.this.arn]
  }

  statement {
    sid    = "AllowGetAuthorizationToken"
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "ecr_image_pusher" {
  name        = "ECRImagePusher"
  description = "Enables to push docker images to ECR"
  policy      = data.aws_iam_policy_document.ecr_image_pusher.json
}

module "iam_github_oidc_role_ecr" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-github-oidc-role"
  version = "5.39.1"

  name        = "${local.app_name_parsed}-github-actions-ecr"
  description = "Allow access to ECR from GitHub actions"

  subjects = ["${var.github_api_repository_name}:*"]
  policies = {
    ECRPusher = aws_iam_policy.ecr_image_pusher.arn
  }
}
