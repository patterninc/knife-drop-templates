terraform {
  required_version = ">=1.11.0"
  required_providers {
    aws = {
      version = ">=5.90.0"
      source  = "hashicorp/aws"
      configuration_aliases = [aws.region]
    }
  }
}