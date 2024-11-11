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
# Groups
##############################################################

module "iam_group_with_policies" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-group-with-policies"
  version = "5.39.1"

  name = "LogReaders"

  attach_iam_self_management_policy = true
  enable_mfa_enforcement            = false
  custom_group_policy_arns = [
    "arn:aws:iam::aws:policy/CloudWatchReadOnlyAccess"
  ]
}
