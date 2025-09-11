output "secret_arns" {
  description = "ARNs of all secrets for ECS configuration"
  value = {
    secret_key     = aws_secretsmanager_secret.django_secret_key.arn
    db_credentials = aws_secretsmanager_secret.db_credentials.arn
  }
}