variable "name" {
  type        = string
  description = "Prefix for resource names"
}

variable "region" {
  type        = string
  description = "AWS region (used in the VPC endpoint service names)"
}

variable "cidr_block" {
  type        = string
  description = "CIDR block of the VPC"
}

variable "availability_zones" {
  type        = list(string)
  description = "Availability zones; one public, app and db subnet is created in each"

  validation {
    condition     = length(var.availability_zones) >= 2
    error_message = "At least two availability zones are required (ALB and RDS Multi-AZ)."
  }
}

variable "static_bucket_name" {
  type        = string
  description = "Static files bucket the tasks may access through the S3 gateway endpoint"
}
