variable "bucket_name" {
  description = "Name of the S3 bucket for static files"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "ecs_task_role_arn" {
  description = "ARN of the ECS task role"
  type        = string
}