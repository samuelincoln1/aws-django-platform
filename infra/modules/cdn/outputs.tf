output "distribution_arn" {
  description = "ARN of the CloudFront distribution"
  value       = aws_cloudfront_distribution.main.arn
}

output "domain_name" {
  description = "CloudFront domain name (target of the DNS record)"
  value       = aws_cloudfront_distribution.main.domain_name
}
