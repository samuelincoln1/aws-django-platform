output "django_secret_key_arn" {
  description = "ARN of the Django SECRET_KEY secret"
  value       = aws_secretsmanager_secret.django_secret_key.arn
}

output "db_credentials_arn" {
  description = "ARN of the database credentials secret (JSON with username and password)"
  value       = aws_secretsmanager_secret.db_credentials.arn
}
