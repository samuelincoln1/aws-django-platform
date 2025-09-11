# VPC
output "vpc_id" {
  description = "ID da VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr_block" {
  description = "CIDR block da VPC"
  value       = aws_vpc.main.cidr_block
}

# Public Subnets
output "public_subnet_ids" {
  description = "IDs das subnets públicas"
  value       = [aws_subnet.public_az1.id, aws_subnet.public_az2.id]
}

output "public_subnet_az1_id" {
  description = "ID da subnet pública AZ1"
  value       = aws_subnet.public_az1.id
}

output "public_subnet_az2_id" {
  description = "ID da subnet pública AZ2"
  value       = aws_subnet.public_az2.id
}

# Private ECS Subnets
output "private_ecs_subnet_ids" {
  description = "IDs das subnets privadas para ECS"
  value       = [aws_subnet.private_ecs_az1.id, aws_subnet.private_ecs_az2.id]
}

output "private_ecs_subnet_az1_id" {
  description = "ID da subnet privada ECS AZ1"
  value       = aws_subnet.private_ecs_az1.id
}

output "private_ecs_subnet_az2_id" {
  description = "ID da subnet privada ECS AZ2"
  value       = aws_subnet.private_ecs_az2.id
}

# Private RDS Subnets
output "private_rds_subnet_ids" {
  description = "IDs das subnets privadas para RDS"
  value       = [aws_subnet.private_rds_az1.id, aws_subnet.private_rds_az2.id]
}

output "private_rds_subnet_az1_id" {
  description = "ID da subnet privada RDS AZ1 (primary)"
  value       = aws_subnet.private_rds_az1.id
}

output "private_rds_subnet_az2_id" {
  description = "ID da subnet privada RDS AZ2 (standby)"
  value       = aws_subnet.private_rds_az2.id
}

# Internet Gateway
output "internet_gateway_id" {
  description = "ID do Internet Gateway"
  value       = aws_internet_gateway.main.id
}

output "vpc_endpoints_security_group_id" {
  description = "ID of the security group of the VPC endpoints"
  value       = aws_security_group.vpc_endpoints.id
}