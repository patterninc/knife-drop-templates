locals {
  account_id      = "{ACCOUNT_ID}"
  account_profile = "{ACCOUNT_PROFILE}"
  account_region  = "{ACCOUNT_REGION}"
  github_repo     = "{GITHUB_REPO}"

  app_name        = "{NAME}"
  environment     = "{ENVIRONMENT}"
  infra_region    = "{INFRA_REGION}"
  repo            = "{NAME}-{ENVIRONMENT}-{INFRA_REGION}"
  ecrUrl          = "{ACCOUNT_ID}.dkr.ecr.{INFRA_REGION}.amazonaws.com"
  docker_image    = "{ACCOUNT_ID}.dkr.ecr.{INFRA_REGION}.amazonaws.com/${local.repo}"
}

