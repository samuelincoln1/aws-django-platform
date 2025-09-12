variable "cidr_block" {
  type        = string
  description = "The CIDR block for the VPC"
}

variable "enable_dns_hostnames" {
  type        = bool
  description = "Whether to enable DNS hostnames for the VPC"
}

variable "enable_dns_support" {
  type        = bool
  description = "Whether to enable DNS support for the VPC"
}

variable "map_public_ip_on_launch" {
  type        = bool
  description = "Whether to map public IP on launch for the public subnets"
}

variable "availability_zone_1" {
  type        = string
  description = "First availability zone"
}

variable "availability_zone_2" {
  type        = string
  description = "Second availability zone"
}

variable "public_subnet_cidr_block_1" {
  type        = string
  description = "CIDR block for public subnet in AZ1"
}

variable "public_subnet_cidr_block_2" {
  type        = string
  description = "CIDR block for public subnet in AZ2"
}

variable "private_subnet_ecs_cidr_1" {
  type        = string
  description = "CIDR block for private ECS subnet in AZ1"
}

variable "private_subnet_ecs_cidr_2" {
  type        = string
  description = "CIDR block for private ECS subnet in AZ2"
}

variable "private_subnet_rds_cidr_1" {
  type        = string
  description = "CIDR block for private RDS subnet in AZ1 (primary)"
}

variable "private_subnet_rds_cidr_2" {
  type        = string
  description = "CIDR block for private RDS subnet in AZ2 (standby)"
}

variable "s3_bucket_name" {
  type        = string
  description = "Name of the S3 bucket"
}