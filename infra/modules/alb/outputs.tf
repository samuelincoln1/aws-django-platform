output "alb_dns_name" {
  description = "DNS name of the ALB (CloudFront origin)"
  value       = aws_lb.main.dns_name
}

output "security_group_id" {
  description = "Security group of the ALB"
  value       = aws_security_group.alb.id
}

output "target_group_arn" {
  description = "Target group of the ECS service"
  value       = aws_lb_target_group.app.arn
}
