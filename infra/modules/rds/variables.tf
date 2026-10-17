variable "name" {
  type        = string
  description = "Prefix for resource names (also the DB instance identifier)"
}

variable "vpc_id" {
  type        = string
  description = "VPC where the database is deployed"
}

variable "subnet_ids" {
  type        = list(string)
  description = "Private subnets in at least two AZs"
}

variable "allowed_security_group_ids" {
  type        = list(string)
  description = "Security groups allowed to connect on port 5432"
}

variable "db_name" {
  type        = string
  description = "Name of the database created on the instance"
}

variable "username" {
  type        = string
  description = "Master username"
}

variable "password" {
  type        = string
  description = "Master password (write-only, not stored in state)"
  sensitive   = true
  ephemeral   = true
}

variable "password_version" {
  type        = number
  description = "Increment to apply a new password"
}

variable "engine_version" {
  type        = string
  description = "PostgreSQL version. A major version (\"17\") picks the default minor"
  default     = "17"
}

variable "instance_class" {
  type        = string
  description = "RDS instance class"
  default     = "db.t3.micro"
}

variable "allocated_storage" {
  type        = number
  description = "Initial storage in GB"
  default     = 20
}

variable "max_allocated_storage" {
  type        = number
  description = "Storage autoscaling ceiling in GB"
  default     = 100
}

variable "multi_az" {
  type        = bool
  description = "Synchronous standby in a second AZ with automatic failover"
  default     = true
}

variable "deletion_protection" {
  type        = bool
  description = "Block deletion of the instance. Set to false before `terraform destroy`"
  default     = true
}
