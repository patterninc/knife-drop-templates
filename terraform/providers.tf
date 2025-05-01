locals {
  account_id          = "{ACCOUNT_ID}"
  account_profile     = "{ACCOUNT_PROFILE}"
  account_region      = "{ACCOUNT_REGION}"
  github_repo         = "{GITHUB_REPO}"
}

terraform {
  required_version = ">=1.11.0"
  required_providers {
    aws = {
      version = ">=5.90.0"
      source  = "hashicorp/aws"
    }
  }
  backend "s3" {
    bucket         = "terraform-state-storage-{ACCOUNT_ID}"
    key            = "{GITHUB_REPO}.tfstate"
    region         = "{ACCOUNT_REGION}"
    dynamodb_table = "terraform-state-lock-{ACCOUNT_ID}"
    profile        = "{ACCOUNT_PROFILE}"
  }
}

provider "aws" {
  region  = "us-west-2"
  profile = local.account_profile
}

provider "aws" {
  region  = "us-west-2"
  profile = local.account_profile
  alias   = "us-west-2"
}

provider "aws" {
  region  = "us-east-1"
  profile = local.account_profile
  alias   = "us-east-1"
}