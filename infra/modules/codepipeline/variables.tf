variable "project_name" {
  description = "Project name"
  type        = string
  default     = "django-app"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "devops-test"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "aws_account_id" {
  description = "AWS account ID"
  type        = string
}

variable "bitbucket_repo_name" {
  description = "Bitbucket repository name"
  type        = string
}

variable "branch_name" {
  description = "Branch name for pipeline trigger"
  type        = string
  default     = "main"  
}

variable "ecr_repository_name" {
  description = "ECR repository name"
  type        = string
}

variable "ecr_repository_url" {
  description = "ECR repository URL"
  type        = string
}

variable "ecs_cluster_name" {
  description = "ECS cluster name"
  type        = string
}

variable "ecs_service_name" {
  description = "ECS service name"
  type        = string
}

variable "ecs_task_execution_role_arn" {
  description = "ECS task execution role ARN"
  type        = string
}

variable "ecs_task_role_arn" {
  description = "ECS task role ARN"
  type        = string
}