variable "cluster_name" {
  type        = string
  description = "ECS cluster name"
  default     = "django-app-cluster"
}

variable "service_name" {
  type        = string
  description = "ECS service name"
  default     = "django-app-service"
}

variable "environment" {
  type        = string
  description = "Environment name"
  default     = "devops-test"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID"
}

variable "vpc_cidr_block" {
  type        = string
  description = "VPC CIDR block"
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "Private subnets for ECS"
}

variable "alb_target_group_arn" {
  type        = string
  description = "ARN of the target group of the ALB"
}

variable "alb_security_group_id" {
  type        = string
  description = "ID of the security group of the ALB"
}

variable "container_image" {
  type        = string
  description = "URI of the Docker image in ECR"
}

variable "desired_count" {
  type        = number
  description = "Desired number of tasks"
  default     = 6
}

variable "cpu" {
  type        = number
  description = "CPU for each task (in units)"
  default     = 512
}

variable "memory" {
  type        = number
  description = "Memory for each task (in MB)"
  default     = 1024
}

variable "vpc_endpoints_security_group_id" {
  type        = string
  description = "ID of the security group of the VPC endpoints"
}

variable "django_debug" {
  type        = string
  description = "Django DEBUG setting"
  default     = "False"
}

variable "django_allowed_hosts" {
  type        = string
  description = "Django ALLOWED_HOSTS"
}

variable "db_host" {
  type        = string
  description = "Database host"
  default     = "localhost"
}

variable "db_port" {
  type        = string
}

variable "db_name" {
  type        = string
  description = "Database name"
  default     = "app"
}

variable "use_s3" { 
  type        = string
  description = "Whether to use S3 for static files"
  default     = "false"
}

variable "aws_storage_bucket_name" {
  type        = string
  description = "S3 bucket name for static files"
}

variable "aws_region" {
  type        = string
  description = "AWS region"
  default     = "us-east-1"
}

variable "secret_arns" {
  description = "ARNs of secrets from Secrets Manager"
  type = object({
    secret_key     = string
    db_credentials = string
  })
}

variable "s3_bucket_arn" {
  description = "ARN of the S3 bucket for static files"
  type        = string
  default     = ""
}

variable "max_capacity" {
  description = "Maximum number of tasks"
  type        = number
  default     = 6
}

variable "scale_up_target" {
  description = "Target value for scale up"
  type        = number
  default     = 70.0
}

variable "scale_in_cooldown" {
  description = "Cooldown for scale in"
  type        = number
  default     = 300
}

variable "scale_out_cooldown" {
  description = "Cooldown for scale out"
  type        = number
  default     = 300
}
