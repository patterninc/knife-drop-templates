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
  vpc_name        = "{VPC_NAME}"

  task_cpu        = 1024
  task_memory     = 2048
  use_graviton    = true
  container_image = "${local.docker_image}:latest"

  domain_name     = "{DOMAIN_NAME}"
  app_domain_name = "{NAME}.{DOMAIN_NAME}"
}

module "fargate" {
  source          = "github.com/patterninc/terraform-aws-fargate?ref=v3.4.1"
  app_name        = local.app_name
  container_image = local.container_image
  use_graviton    = local.use_graviton
  task_cpu        = local.task_cpu
  task_memory     = local.task_memory

  vpc_id              = data.aws_vpc.vpc.id
  subnet_ids          = data.aws_subnets.private.ids
  load_balancer_sg_id = module.alb.alb_security_group.id
  target_groups       = values(module.alb.target_groups)

  tags                          = module.this.tags
  role_permissions_boundary_arn = null
  module_depends_on             = [module.alb.alb]
  context                       = module.this.context

  providers = {
    aws = aws.{INFRA_REGION}
  }
}

module "acm_certificate" {
  source                 = "github.com/patterninc/terraform-acm-ssl-cert.git?ref=v1.2.1"
  cetificate_domain_name = local.app_domain_name
  providers = {
    aws = aws.{INFRA_REGION}
  }
}

module "alb" {
  source     = "github.com/patterninc/terraform-aws-alb.git?ref=v1.4.9"
  name       = "aws-fargate-example-alb"
  vpc_id     = data.aws_vpc.vpc.id
  subnet_ids = data.aws_subnets.public.ids
  target_groups = {
    main = {
      port                 = 3000
      protocol             = "HTTP"
      type                 = "ip"
      health_check = {
        path                = "/"
        interval            = 30
        timeout             = 10
        healthy_threshold   = 1
        unhealthy_threshold = 5
      }
    }
  }
  listeners = {
    80 = {
      protocol              = "HTTP"
      https_certificate_arn = null
      redirect_to = {
        host     = null
        path     = null
        port     = 443
        protocol = "HTTPS"
      }
      forward_to = null
    },
    443 = {
      protocol              = "HTTPS"
      https_certificate_arn = module.acm_certificate.arn
      ssl_policy            = "ELBSecurityPolicy-TLS-1-2-Ext-2018-06"
      redirect_to           = null
      forward_to = {
        target_group   = "main"
        ignore_changes = true
      }
    }
  }

  providers = {
    aws = aws.{INFRA_REGION}
  }
}

output "alb_endpoint" {
  value = module.alb.alb.dns_name
}