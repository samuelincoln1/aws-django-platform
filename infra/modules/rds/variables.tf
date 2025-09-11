variable "environment" {
  type        = string
  description = "Environment name"
  default     = "devops-test"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID where RDS will be deployed"
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "Private subnet IDs for RDS (must be in different AZs)"
}

variable "vpc_cidr_block" {
  type        = string
  description = "VPC CIDR block for database access"
}

variable "db_name" {
  type        = string
  description = "Database name"
  default     = "app"
}

variable "db_username" {
  type        = string
  description = "Database master username"
  default     = "app"
}

variable "db_password" {
  type        = string
  description = "Database master password"
  sensitive   = true
}

variable "allocated_storage" {
  type        = number
  description = "Initial allocated storage in GB"
  default     = 20
}

variable "max_allocated_storage" {
  type        = number
  description = "Maximum allocated storage for autoscaling in GB"
  default     = 100
}

variable "instance_class" {
  type        = string
  description = "RDS instance class"
  default     = "db.t3.micro"  # Ideal para desenvolvimento/teste
}

variable "engine_version" {
  type        = string
  description = "PostgreSQL engine version"
  default     = "15.7"
}

variable "backup_retention_period" {
  type        = number
  description = "Number of days to retain backups"
  default     = 7
}

variable "backup_window" {
  type        = string
  description = "Preferred backup window"
  default     = "03:00-04:00"
}

variable "maintenance_window" {
  type        = string
  description = "Preferred maintenance window"
  default     = "sun:04:00-sun:05:00"
}

variable "multi_az" {
  type        = bool
  description = "Enable Multi-AZ deployment for high availability"
  default     = false  # Para desenvolvimento, pode ser false
}

variable "deletion_protection" {
  type        = bool
  description = "Enable deletion protection"
  default     = false  # Para desenvolvimento, pode ser false
}

variable "skip_final_snapshot" {
  type        = bool
  description = "Skip final snapshot when destroying"
  default     = true   # Para desenvolvimento, pode ser true
}

variable "monitoring_interval" {
  type        = number
  description = "Enhanced monitoring interval in seconds (0 to disable)"
  default     = 60
}

variable "performance_insights_enabled" {
  type        = bool
  description = "Enable Performance Insights"
  default     = true
}

variable "performance_insights_retention_period" {
  type        = number
  description = "Performance Insights retention period in days"
  default     = 7
} 