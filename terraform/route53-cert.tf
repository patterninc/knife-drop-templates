
data "aws_route53_zone" "account_domain" {
  name         = local.domain_name
  private_zone = false
}

resource "aws_acm_certificate" "cert" {
  domain_name               = local.domain_name
  subject_alternative_names = ["*.${local.domain_name}"]
  validation_method         = "DNS"
  tags = {
    Name        = "${local.app_name}-${local.environment}-cert"
    Environment = local.environment
    Github_Repo = local.github_repo
  }
  provider = aws.{INFRA_REGION}
}

resource "aws_acm_certificate_validation" "cert_validate" {
  certificate_arn = aws_acm_certificate.cert.arn
  validation_record_fqdns = [
    for record in aws_acm_certificate.cert.domain_validation_options : record.resource_record_name
  ]
}

data "aws_lb" "alb" {
  name = "${local.app_name}-${local.environment}-alb"
  depends_on = [ module.alb ]
}

resource "aws_route53_record" "app_domain" {
  zone_id = data.aws_route53_zone.account_domain.zone_id
  name = local.app_domain_name
  type    = "A"
  alias {
    name                   = data.aws_lb.alb.dns_name
    zone_id                = data.aws_lb.alb.zone_id
    evaluate_target_health = true
  }
}