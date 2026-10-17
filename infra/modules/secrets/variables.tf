variable "name" {
  description = "Prefix of the secret names"
  type        = string
}

variable "django_secret_key" {
  description = "Django SECRET_KEY"
  type        = string
  sensitive   = true
  ephemeral   = true
}

variable "db_username" {
  description = "Database user"
  type        = string
}

variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
  ephemeral   = true
}

variable "secrets_version" {
  description = "Increment to send new secret values"
  type        = number
}

variable "recovery_window_in_days" {
  description = "Days a deleted secret can still be restored"
  type        = number
  default     = 7
}
