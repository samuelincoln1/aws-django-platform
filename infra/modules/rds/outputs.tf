output "db_instance_id" {
  description = "RDS instance ID"
  value       = aws_db_instance.postgresql.id
}

output "db_instance_arn" {
  description = "RDS instance ARN"
  value       = aws_db_instance.postgresql.arn
}

output "db_endpoint" {
  description = "Database endpoint for application connection"
  value       = aws_db_instance.postgresql.address
}

output "db_port" {
  description = "Database port"
  value       = aws_db_instance.postgresql.port
}

output "db_name" {
  description = "Database name"
  value       = aws_db_instance.postgresql.db_name
}

output "db_security_group_id" {
  description = "Security Group ID of the RDS instance"
  value       = aws_security_group.rds.id
}

output "db_monitoring_role_arn" {
  description = "Enhanced monitoring role ARN"
  value       = aws_iam_role.rds_enhanced_monitoring.arn
}

output "db_connection_info" {
  description = "Database connection information"
  value = {
    host     = aws_db_instance.postgresql.address
    port     = aws_db_instance.postgresql.port
    database = aws_db_instance.postgresql.db_name
    username = aws_db_instance.postgresql.username
  }
  sensitive = false
}

output "db_backup_info" {
  description = "Database backup configuration"
  value = {
    backup_retention_period = aws_db_instance.postgresql.backup_retention_period
    backup_window           = aws_db_instance.postgresql.backup_window
    maintenance_window      = aws_db_instance.postgresql.maintenance_window
  }
}