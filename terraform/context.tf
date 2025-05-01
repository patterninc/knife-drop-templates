module "this" {
  source      = "github.com/patterninc/terraform-aws-labels.git?ref=v1.2.1"
  enabled     = true
  environment = "{ENVIRONMENT}"
  name        = "{NAME}"
  delimiter   = var.delimiter
  attributes  = var.attributes
  tags        = {
    CreatedBy   = "Terraform"
    Environment = "{ENVIRONMENT}"
    Team        = "{TEAM}"
    Owner       = "{TEAM}"
    Github_Repo = "{GITHUB_REPO}"
  }
  context     = var.context
}

variable "tags" {
  type = map(string)
  default = 
}
