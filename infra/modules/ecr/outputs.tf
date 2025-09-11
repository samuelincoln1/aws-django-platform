output "repository_url" {
  description = "URL of the ECR repository"
  value       = aws_ecr_repository.django_app.repository_url
}

output "repository_name" {
  description = "Name of the ECR repository"
  value       = aws_ecr_repository.django_app.name
}

output "registry_id" {
  description = "Registry ID of the ECR"
  value       = aws_ecr_repository.django_app.registry_id
}