# Django Secret Key
resource "aws_secretsmanager_secret" "django_secret_key" {
  name                    = "django-app/secret-key"
  description             = "Django SECRET_KEY"
  recovery_window_in_days = 7
}

resource "aws_secretsmanager_secret_version" "django_secret_key" {
  secret_id     = aws_secretsmanager_secret.django_secret_key.id
  secret_string = var.django_secret_key
}

# Database Credentials (apenas user/password)
resource "aws_secretsmanager_secret" "db_credentials" {
  name                    = "django-app/db-credentials"
  description             = "Database credentials"
  recovery_window_in_days = 7
}

resource "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    username = var.db_user
    password = var.db_password
  })
}