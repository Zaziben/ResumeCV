
import {
  to = aws_route53_zone.primary
  id = "Z045138939V9ZXCN9Y933"
}

resource "aws_route53_zone" "primary" {
  name = "joshvvcv.com"
}

resource "aws_acm_certificate" "cert" {
  domain_name       = "joshvvcv.com"
  validation_method = "DNS"
  subject_alternative_names = ["www.joshvvcv.com","api.joshvvcv.com"]
}

resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => {       
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      record = dvo.resource_record_value
    }
  }
  zone_id = aws_route53_zone.primary.zone_id
  name    = each.value.name
  type    = each.value.type
  records = [each.value.record]
  ttl     = 60
  allow_overwrite = true
}

resource "aws_acm_certificate_validation" "cert_validation" {
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]      
}
