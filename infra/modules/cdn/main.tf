data "aws_cloudfront_cache_policy" "disabled" {
  name = "Managed-CachingDisabled"
}

data "aws_cloudfront_cache_policy" "optimized" {
  name = "Managed-CachingOptimized"
}

# Forwards Host, cookies, query strings and headers to the ALB. Because the
# Host header is forwarded, CloudFront validates the ALB certificate against
# domain_name, so the ALB listener uses a certificate for the same domain.
data "aws_cloudfront_origin_request_policy" "all_viewer" {
  name = "Managed-AllViewer"
}

resource "aws_cloudfront_origin_access_control" "static" {
  name                              = "${var.name}-static"
  description                       = "Access to the static files bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "main" {
  enabled         = true
  is_ipv6_enabled = true
  http_version    = "http2and3"
  price_class     = var.price_class
  aliases         = [var.domain_name]
  web_acl_id      = var.web_acl_arn
  comment         = var.name

  origin {
    origin_id   = "alb"
    domain_name = var.alb_dns_name

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }

    custom_header {
      name  = var.origin_verify_header_name
      value = var.origin_verify_header_value
    }
  }

  origin {
    origin_id                = "static"
    domain_name              = var.static_bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.static.id
  }

  # Application: dynamic, never cached
  default_cache_behavior {
    target_origin_id         = "alb"
    viewer_protocol_policy   = "redirect-to-https"
    allowed_methods          = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods           = ["GET", "HEAD"]
    cache_policy_id          = data.aws_cloudfront_cache_policy.disabled.id
    origin_request_policy_id = data.aws_cloudfront_origin_request_policy.all_viewer.id
    compress                 = true
  }

  # Static files: served from S3 and cached at the edge
  ordered_cache_behavior {
    path_pattern           = "/static/*"
    target_origin_id       = "static"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    cache_policy_id        = data.aws_cloudfront_cache_policy.optimized.id
    compress               = true
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = var.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }
}

resource "aws_s3_bucket_policy" "static" {
  bucket = var.static_bucket_id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowCloudFrontRead"
        Effect    = "Allow"
        Principal = { Service = "cloudfront.amazonaws.com" }
        Action    = "s3:GetObject"
        Resource  = "${var.static_bucket_arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.main.arn
          }
        }
      }
    ]
  })
}

resource "aws_route53_record" "app" {
  for_each = var.route53_zone_id == null ? toset([]) : toset(["A", "AAAA"])

  zone_id = var.route53_zone_id
  name    = var.domain_name
  type    = each.key

  alias {
    name                   = aws_cloudfront_distribution.main.domain_name
    zone_id                = aws_cloudfront_distribution.main.hosted_zone_id
    evaluate_target_health = false
  }
}
