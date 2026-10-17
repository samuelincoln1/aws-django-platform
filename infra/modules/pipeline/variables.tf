variable "name" {
  description = "Prefix for resource names"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "account_id" {
  description = "AWS account ID"
  type        = string
}

variable "repository_provider" {
  description = "GitHub, Bitbucket or GitLab"
  type        = string
}

variable "repository_id" {
  description = "Repository in the form owner/repository"
  type        = string
}

variable "branch_name" {
  description = "Branch that triggers the pipeline"
  type        = string
}

variable "ecr_repository_url" {
  description = "ECR repository URL"
  type        = string
}

variable "ecr_repository_arn" {
  description = "ECR repository ARN"
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

variable "task_definition_family" {
  description = "Task definition family the pipeline registers revisions in"
  type        = string
}

variable "container_name" {
  description = "Container whose image is replaced on deploy"
  type        = string
}

variable "task_subnet_ids" {
  description = "Subnets of the one-off migration task"
  type        = list(string)
}

variable "task_security_group_id" {
  description = "Security group of the one-off migration task"
  type        = string
}

variable "task_role_arns" {
  description = "Roles referenced by the task definition (passed to ECS on register/run)"
  type        = list(string)
}
