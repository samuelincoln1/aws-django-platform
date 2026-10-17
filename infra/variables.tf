variable "project_name" {
  description = "Prefix used to name every resource"
  type        = string
  default     = "django-app"
}

variable "environment" {
  description = "Environment name (prod, staging, ...)"
  type        = string
  default     = "prod"
}

variable "aws_region" {
  description = "Region for the regional resources (VPC, ECS, RDS, ALB)"
  type        = string
  default     = "us-east-1"
}

# ==================== Networking ====================

variable "vpc_cidr" {
  description = "CIDR block of the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "Availability zones used by the public, app and database subnets"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

# ==================== Domain / TLS ====================

variable "domain_name" {
  description = "Public domain of the application (e.g. app.example.com)"
  type        = string
}

variable "cloudfront_certificate_arn" {
  description = "ACM certificate for domain_name, issued in us-east-1 (required by CloudFront)"
  type        = string
}

variable "alb_certificate_arn" {
  description = "ACM certificate for domain_name in aws_region, used on the CloudFront -> ALB hop. Same ARN as cloudfront_certificate_arn when aws_region is us-east-1"
  type        = string
}

variable "route53_zone_id" {
  description = "Hosted zone where the alias record for domain_name is created. Leave null to manage DNS elsewhere"
  type        = string
  default     = null
}

# ==================== Application ====================

variable "static_bucket_name" {
  description = "Globally unique name of the S3 bucket for Django static files"
  type        = string
}

variable "django_secret_key" {
  description = "Django SECRET_KEY. Ephemeral: written to Secrets Manager, never stored in the Terraform state"
  type        = string
  sensitive   = true
  ephemeral   = true
}

variable "db_username" {
  description = "Master username of the PostgreSQL database"
  type        = string
  default     = "app"
}

variable "db_password" {
  description = "Master password of the PostgreSQL database. Ephemeral: never stored in the Terraform state"
  type        = string
  sensitive   = true
  ephemeral   = true
}

variable "secrets_version" {
  description = "Increment to push new values of django_secret_key / db_password (write-only arguments are only sent when this changes)"
  type        = number
  default     = 1
}

variable "task_cpu" {
  description = "CPU units per ECS task (1024 = 1 vCPU)"
  type        = number
  default     = 1024
}

variable "task_memory" {
  description = "Memory (MiB) per ECS task"
  type        = number
  default     = 2048
}

variable "min_tasks" {
  description = "Minimum number of ECS tasks"
  type        = number
  default     = 2
}

variable "max_tasks" {
  description = "Maximum number of ECS tasks"
  type        = number
  default     = 6
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "db_multi_az" {
  description = "Whether the RDS instance has a synchronous standby in a second AZ"
  type        = bool
  default     = true
}

# ==================== CI/CD ====================

variable "repository_provider" {
  description = "Provider of the source repository: GitHub, Bitbucket or GitLab"
  type        = string
  default     = "GitHub"

  validation {
    condition     = contains(["GitHub", "Bitbucket", "GitLab"], var.repository_provider)
    error_message = "repository_provider must be GitHub, Bitbucket or GitLab."
  }
}

variable "repository_id" {
  description = "Full repository id, in the form owner/repository"
  type        = string
}

variable "branch_name" {
  description = "Branch that triggers the pipeline"
  type        = string
  default     = "main"
}
