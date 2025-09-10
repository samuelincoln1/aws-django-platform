# VPC
resource "aws_vpc" "main" {
  cidr_block           = var.cidr_block
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support
  tags = {
    Name = "django-app-vpc"
    Environment = "devops-test"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "django-app-igw"
    Environment = "devops-test"
  }
}

# ==================== AZ 1 (us-east-1a) ====================

resource "aws_subnet" "public_az1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr_block_1
  availability_zone       = var.availability_zone_1
  map_public_ip_on_launch = var.map_public_ip_on_launch
  
  tags = {
    Name        = "public-subnet-az1"
    Environment = "devops-test"
    Type        = "public"
    AZ          = var.availability_zone_1
  }
}

# Private Subnet ECS AZ1
resource "aws_subnet" "private_ecs_az1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_ecs_cidr_1
  availability_zone = var.availability_zone_1
  
  tags = {
    Name        = "private-ecs-subnet-az1"
    Environment = "devops-test"
    Type        = "private-ecs"
    AZ          = var.availability_zone_1
  }
}

# Private Subnet RDS Primary AZ1
resource "aws_subnet" "private_rds_az1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_rds_cidr_1
  availability_zone = var.availability_zone_1
  
  tags = {
    Name        = "private-rds-subnet-az1"
    Environment = "devops-test"
    Type        = "private-rds"
    AZ          = var.availability_zone_1
  }
}

# ==================== AZ 2 (us-east-1b) ====================

# Public Subnet AZ2
resource "aws_subnet" "public_az2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr_block_2
  availability_zone       = var.availability_zone_2
  map_public_ip_on_launch = var.map_public_ip_on_launch
  
  tags = {
    Name        = "public-subnet-az2"
    Environment = "devops-test"
    Type        = "public"
    AZ          = var.availability_zone_2
  }
}

# Private Subnet ECS AZ2
resource "aws_subnet" "private_ecs_az2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_ecs_cidr_2
  availability_zone = var.availability_zone_2
  
  tags = {
    Name        = "private-ecs-subnet-az2"
    Environment = "devops-test"
    Type        = "private-ecs"
    AZ          = var.availability_zone_2
  }
}

# Private Subnet RDS Standby AZ2
resource "aws_subnet" "private_rds_az2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_rds_cidr_2
  availability_zone = var.availability_zone_2
  
  tags = {
    Name        = "private-rds-subnet-az2"
    Environment = "devops-test"
    Type        = "private-rds"
    AZ          = var.availability_zone_2
  }
}
# ==================== Route Tables ====================

# Route Table Public
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  
  tags = {
    Name        = "public-route-table"
    Environment = "devops-test"
  }
}

# Route Table Private
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  
  tags = {
    Name        = "private-route-table"
    Environment = "devops-test"
  }
}

# ==================== Route Table Associations ====================

# Public Subnets
resource "aws_route_table_association" "public_az1" {
  subnet_id      = aws_subnet.public_az1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_az2" {
  subnet_id      = aws_subnet.public_az2.id
  route_table_id = aws_route_table.public.id
}

# Private ECS Subnets
resource "aws_route_table_association" "private_ecs_az1" {
  subnet_id      = aws_subnet.private_ecs_az1.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_ecs_az2" {
  subnet_id      = aws_subnet.private_ecs_az2.id
  route_table_id = aws_route_table.private.id
}

# Private RDS Subnets
resource "aws_route_table_association" "private_rds_az1" {
  subnet_id      = aws_subnet.private_rds_az1.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_rds_az2" {
  subnet_id      = aws_subnet.private_rds_az2.id
  route_table_id = aws_route_table.private.id
}