variable "name" {
  description = "Prefix for resource names"
  type        = string
}

variable "rate_limit" {
  description = "Maximum requests per IP in a 5-minute window before blocking"
  type        = number
  default     = 2000
}

variable "blocked_countries" {
  description = "ISO country codes to block. Empty list disables the rule"
  type        = list(string)
  default     = ["CN", "RU", "KP"]
}
