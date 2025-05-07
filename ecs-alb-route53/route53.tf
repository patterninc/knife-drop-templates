
data "aws_route53_zone" "account_domain" {
  name         = local.domain_name
  private_zone = false
}

resource "aws_route53_record" "app_domain" {
  zone_id = data.aws_route53_zone.account_domain.zone_id
  name    = local.app_domain_name
  type    = "A"
  alias {
    name                   = data.aws_lb.alb.dns_name
    zone_id                = data.aws_lb.alb.zone_id
    evaluate_target_health = true
  }
}