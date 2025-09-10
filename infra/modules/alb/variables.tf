variable "vpc_id" {
  type        = string
  description = "VPC ID"
}

variable "public_subnet_ids" {
  type        = list(string)
  description = "Public Subnet IDs"
}

variable "certificate_arn" {
  type        = string
  description = "SSL/TLS Certificate ARN"
  default     = null
}