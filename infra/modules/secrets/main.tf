# Values are sent with write-only arguments: Terraform passes them to AWS
# but never records them in the state file.

resource "aws_secretsmanager_secret" "django_secret_key" {
  name                    = "${var.name}/django-secret-key"
  description             = "Django SECRET_KEY"
  recovery_window_in_days = var.recovery_window_in_days
}

resource "aws_secretsmanager_secret_version" "django_secret_key" {
  secret_id                = aws_secretsmanager_secret.django_secret_key.id
  secret_string_wo         = var.django_secret_key
  secret_string_wo_version = var.secrets_version
}

resource "aws_secretsmanager_secret" "db_credentials" {
  name                    = "${var.name}/db-credentials"
  description             = "PostgreSQL credentials used by the application"
  recovery_window_in_days = var.recovery_window_in_days
}

resource "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = aws_secretsmanager_secret.db_credentials.id
  secret_string_wo = jsonencode({
    username = var.db_username
    password = var.db_password
  })
  secret_string_wo_version = var.secrets_version
}
