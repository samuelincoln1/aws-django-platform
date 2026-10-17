output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_ids" {
  description = "Public subnets (ALB)"
  value       = aws_subnet.public[*].id
}

output "app_subnet_ids" {
  description = "Private subnets for the ECS tasks"
  value       = aws_subnet.app[*].id
}

output "app_subnet_cidrs" {
  description = "CIDR blocks of the app subnets"
  value       = aws_subnet.app[*].cidr_block
}

output "db_subnet_ids" {
  description = "Private subnets for RDS"
  value       = aws_subnet.db[*].id
}

output "db_subnet_cidrs" {
  description = "CIDR blocks of the database subnets"
  value       = aws_subnet.db[*].cidr_block
}

output "vpc_endpoints_security_group_id" {
  description = "Security group of the interface VPC endpoints"
  value       = aws_security_group.vpc_endpoints.id
}

output "s3_prefix_list_id" {
  description = "Prefix list of the S3 gateway endpoint, for security group egress rules"
  value       = aws_vpc_endpoint.s3.prefix_list_id
}
