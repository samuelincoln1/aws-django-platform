output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = aws_lb.main.arn
}

output "alb_dns_name" {
  description = "DNS name of the ALB to access the application"
  value       = aws_lb.main.dns_name
}

output "alb_zone_id" {
  description = "Zone ID of the ALB (for Route 53)"
  value       = aws_lb.main.zone_id
}

output "alb_security_group_id" {
  description = "ID of the Security Group of the ALB"
  value       = aws_security_group.alb.id
}

output "target_group_arn" {
  description = "ARN of the Target Group for ECS"
  value       = aws_lb_target_group.ecs.arn
}

output "target_group_name" {
  description = "Name of the Target Group for ECS"
  value       = aws_lb_target_group.ecs.name
}

output "alb_url" {
  description = "Full URL to access the application"
  value       = "http://${aws_lb.main.dns_name}"
}