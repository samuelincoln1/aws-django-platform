variable "name" {
  type        = string
  description = "Prefix for resource names (cluster, service and task family)"
}

variable "region" {
  type        = string
  description = "AWS region (for the awslogs driver)"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID"
}

variable "subnet_ids" {
  type        = list(string)
  description = "Private subnets for the tasks"
}

variable "db_subnet_cidrs" {
  type        = list(string)
  description = "CIDR blocks of the database subnets"
}

variable "vpc_endpoints_security_group_id" {
  type        = string
  description = "Security group of the interface VPC endpoints"
}

variable "s3_prefix_list_id" {
  type        = string
  description = "Prefix list of the S3 gateway endpoint"
}

variable "alb_security_group_id" {
  type        = string
  description = "Security group of the ALB"
}

variable "target_group_arn" {
  type        = string
  description = "ALB target group of the service"
}

variable "container_image" {
  type        = string
  description = "Image of the first task definition revision"
}

variable "container_port" {
  type        = number
  description = "Port gunicorn listens on"
  default     = 8000
}

variable "cpu" {
  type        = number
  description = "CPU units per task"
}

variable "memory" {
  type        = number
  description = "Memory (MiB) per task"
}

variable "min_capacity" {
  type        = number
  description = "Minimum number of tasks"
}

variable "max_capacity" {
  type        = number
  description = "Maximum number of tasks"
}

variable "scale_target_cpu" {
  type        = number
  description = "Average CPU utilization (%) the autoscaling policy keeps"
  default     = 70
}

variable "environment" {
  type        = map(string)
  description = "Plain environment variables of the container"
}

variable "secrets" {
  type        = map(string)
  description = "Environment variables injected from Secrets Manager (name => valueFrom)"
}

variable "secret_arns" {
  type        = list(string)
  description = "Secrets the execution role may read"
}

variable "static_bucket_arn" {
  type        = string
  description = "Bucket that receives the static files"
}

variable "log_retention_days" {
  type        = number
  description = "Retention of the application logs"
  default     = 30
}
