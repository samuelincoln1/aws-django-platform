output "address" {
  description = "Hostname of the database"
  value       = aws_db_instance.postgresql.address
}

output "port" {
  description = "Port of the database"
  value       = aws_db_instance.postgresql.port
}

output "db_name" {
  description = "Name of the application database"
  value       = aws_db_instance.postgresql.db_name
}

output "security_group_id" {
  description = "Security group of the database"
  value       = aws_security_group.rds.id
}
