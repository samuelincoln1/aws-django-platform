output "web_acl_arn" {
  description = "ARN of the WAF web ACL (used by CloudFront)"
  value       = aws_wafv2_web_acl.main.arn
}
