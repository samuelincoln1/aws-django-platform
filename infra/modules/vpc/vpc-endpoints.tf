# S3 Gateway Endpoint 
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.us-east-1.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.private.id]


  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid = "ECRAccess"
        Effect = "Allow"
        Principal = "*"
        Action = [
          "s3:GetObject"
        ]
        Resource = [
          "arn:aws:s3:::prod-us-east-1-starport-layer-bucket/*"
        ]
      },
      {
        Sid = "StaticFilesAccess"
        Effect = "Allow"
        Principal = "*"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:HeadObject",    
          "s3:ListBucket",
          "s3:GetBucketLocation"
        ]
        Resource = [
          "arn:aws:s3:::samuel-lincoln-django-app-static",
          "arn:aws:s3:::samuel-lincoln-django-app-static/*"
        ]
      }
    ]
  })

  tags = {
    Name        = "s3-vpc-endpoint"
    Environment = "devops-test"
  }
}

# ECR Docker Interface Endpoint
resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.us-east-1.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.private_ecs_az1.id, aws_subnet.private_ecs_az2.id]
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = {
    Name        = "ecr-dkr-vpc-endpoint"
    Environment = "devops-test"
  }
}

# ECR API Interface Endpoint
resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.us-east-1.ecr.api"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.private_ecs_az1.id, aws_subnet.private_ecs_az2.id]
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = {
    Name        = "ecr-api-vpc-endpoint"
    Environment = "devops-test"
  }
}

# Logs Interface Endpoint
resource "aws_vpc_endpoint" "logs" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.us-east-1.logs"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.private_ecs_az1.id, aws_subnet.private_ecs_az2.id]
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = {
    Name        = "logs-vpc-endpoint"
    Environment = "devops-test"
  }
}

# Secrets Manager Interface Endpoint
resource "aws_vpc_endpoint" "secretsmanager" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.us-east-1.secretsmanager"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.private_ecs_az1.id, aws_subnet.private_ecs_az2.id]
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = {
    Name        = "secretsmanager-vpc-endpoint"
    Environment = "devops-test"
  }
}

# Security Group para VPC Endpoints
resource "aws_security_group" "vpc_endpoints" {
  name_prefix = "vpc-endpoints-devops-test-"
  vpc_id      = aws_vpc.main.id
  description = "Security group for VPC endpoints"

  # Permitir HTTPS das tasks ECS
  ingress {
    description = "HTTPS from ECS tasks"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [
      "10.0.3.0/24", # ECS subnet AZ1
      "10.0.4.0/24"  # ECS subnet AZ2
    ]
  }

  # Permitir HTTP das tasks ECS (às vezes necessário)
  ingress {
    description = "HTTP from ECS tasks"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [
      "10.0.3.0/24", # ECS subnet AZ1
      "10.0.4.0/24"  # ECS subnet AZ2
    ]
  }

  tags = {
    Name        = "vpc-endpoints-sg"
    Environment = "devops-test"
  }

  lifecycle {
    create_before_destroy = true
  }
}
