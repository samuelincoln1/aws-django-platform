output "ecs_task_role_arn" {
  description = "ARN of the ECS task role for S3 access"
  value       = aws_iam_role.ecs_task_role.arn
}