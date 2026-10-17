output "cluster_name" {
  description = "Name of the ECS cluster"
  value       = aws_ecs_cluster.main.name
}

output "service_name" {
  description = "Name of the ECS service"
  value       = aws_ecs_service.app.name
}

output "task_definition_family" {
  description = "Family of the task definition"
  value       = aws_ecs_task_definition.app.family
}

output "container_name" {
  description = "Name of the application container"
  value       = local.container_name
}

output "tasks_security_group_id" {
  description = "Security group of the tasks"
  value       = aws_security_group.tasks.id
}

output "task_role_arn" {
  description = "IAM role of the application"
  value       = aws_iam_role.task.arn
}

output "execution_role_arn" {
  description = "IAM role of the ECS agent"
  value       = aws_iam_role.execution.arn
}
