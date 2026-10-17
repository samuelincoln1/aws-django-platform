variable "name" {
  type        = string
  description = "Prefix for resource names"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID"
}

variable "public_subnet_ids" {
  type        = list(string)
  description = "Public subnets for the ALB"
}

variable "app_subnet_cidrs" {
  type        = list(string)
  description = "CIDR blocks of the subnets where the targets run"
}

variable "certificate_arn" {
  type        = string
  description = "ACM certificate of the HTTPS listener"
}

variable "target_port" {
  type        = number
  description = "Port the application listens on"
  default     = 8000
}

variable "health_check_path" {
  type        = string
  description = "Path of the target group health check"
  default     = "/healthz/"
}

variable "origin_verify_header_name" {
  type        = string
  description = "Header CloudFront adds to origin requests"
  default     = "X-Origin-Verify"
}

variable "origin_verify_header_value" {
  type        = string
  description = "Expected value of the origin verify header"
  sensitive   = true
}
