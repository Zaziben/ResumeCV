locals {
  s3_origin_id = "joshvvcv.com"
}

resource "aws_cloudfront_origin_access_control" "current" {
  name                              = "OAC ${aws_s3_bucket.s3.bucket}"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "cdn" {
   depends_on = [aws_s3_bucket.s3]
   origin {
    domain_name = aws_s3_bucket.s3.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.current.id
    origin_id   = "joshvvcv.com-origin"
  }
  comment         = "joshvvcv.com distribution"
  enabled             = true
  is_ipv6_enabled     = false
  default_root_object = "index.html"
  http_version    = "http2and3"
  price_class     = "PriceClass_100" // Use only North America and Europe
  // wait_for_deployment = true

  aliases = ["joshvvcv.com", "www.joshvvcv.com"]

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "joshvvcv.com-origin"
    response_headers_policy_id = aws_cloudfront_response_headers_policy.safe_csp.id

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
  }

  viewer_certificate {
    acm_certificate_arn            = aws_acm_certificate.cert.arn
    ssl_support_method             = "sni-only"
    minimum_protocol_version       = "TLSv1.2_2021"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
}

resource "aws_cloudfront_response_headers_policy" "safe_csp" {
  name = "static-site-safe-csp"

  security_headers_config {
    content_security_policy {
      override = true
      content_security_policy = "media-src 'self' data:; default-src 'self'; script-src 'self'; script-src-elem 'self'; style-src 'self' 'unsafe-inline' https://fonts.googleapis.com; font-src 'self' https://fonts.gstatic.com; connect-src 'self' https://api.joshvvcv.com; object-src 'none'; base-uri 'self';"

    }

    content_type_options {
      override = true
    }

    frame_options {
      frame_option = "DENY"
      override     = true
    }

    referrer_policy {
      referrer_policy = "strict-origin-when-cross-origin"
      override        = true
    }
  }
}


resource "aws_route53_record" "root" {
  zone_id = aws_route53_zone.primary.zone_id
  name    = "joshvvcv.com"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.cdn.domain_name
    zone_id                = aws_cloudfront_distribution.cdn.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "www" {
  zone_id = aws_route53_zone.primary.zone_id
  name    = "www.joshvvcv.com"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.cdn.domain_name
    zone_id                = aws_cloudfront_distribution.cdn.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "api" {
  zone_id = aws_route53_zone.primary.zone_id
  name    = "api.joshvvcv.com"
  type    = "A"

  alias {
    name                   = module.lambda_visitor_counter.api_custom_domain_name
    zone_id                = module.lambda_visitor_counter.api_hosted_zone_id
    evaluate_target_health = false
  }
}


