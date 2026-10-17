variable "name" {
  type        = string
  description = "Prefix for resource names"
}

variable "domain_name" {
  type        = string
  description = "Public domain of the application"
}

variable "certificate_arn" {
  type        = string
  description = "ACM certificate for domain_name, in us-east-1"
}

variable "route53_zone_id" {
  type        = string
  description = "Hosted zone for the alias records. Null skips DNS"
  default     = null
}

variable "web_acl_arn" {
  type        = string
  description = "WAF web ACL attached to the distribution"
}

variable "price_class" {
  type        = string
  description = "CloudFront price class"
  default     = "PriceClass_100"
}

variable "alb_dns_name" {
  type        = string
  description = "DNS name of the ALB origin"
}

variable "origin_verify_header_name" {
  type        = string
  description = "Header added to requests sent to the ALB"
  default     = "X-Origin-Verify"
}

variable "origin_verify_header_value" {
  type        = string
  description = "Secret value of the origin verify header"
  sensitive   = true
}

variable "static_bucket_id" {
  type        = string
  description = "Name of the static files bucket"
}

variable "static_bucket_arn" {
  type        = string
  description = "ARN of the static files bucket"
}

variable "static_bucket_regional_domain_name" {
  type        = string
  description = "Regional domain name of the static files bucket"
}
