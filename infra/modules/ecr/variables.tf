variable "name" {
  description = "Name of the ECR repository"
  type        = string
}

variable "images_to_keep" {
  description = "Number of images kept in the repository"
  type        = number
  default     = 20
}
