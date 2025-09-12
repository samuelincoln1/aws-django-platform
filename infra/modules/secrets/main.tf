resource "aws_secretsmanager_secret" "django_secret_key" {
  name                    = "django-app/secret-key-v3"
  description             = "Django SECRET_KEY"
  recovery_window_in_days = 0
  
  lifecycle {
    create_before_destroy = false
  }
}

resource "aws_secretsmanager_secret_version" "django_secret_key" {
  secret_id     = aws_secretsmanager_secret.django_secret_key.id
  secret_string = var.django_secret_key
}

resource "aws_secretsmanager_secret" "db_credentials" {
  name                    = "django-app/db-credentials-v3"
  description             = "Database credentials"
  recovery_window_in_days = 0  #TROCAR TALVEZ
  
  lifecycle {
    create_before_destroy = false
  }
}

resource "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    username = var.db_user
    password = var.db_password
  })
}