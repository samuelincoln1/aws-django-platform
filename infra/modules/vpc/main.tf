locals {
  az_count = length(var.availability_zones)

  # One /24 per subnet and AZ, in blocks: public, then app, then database.
  # With 2 AZs and 10.0.0.0/16: public 10.0.1-2, app 10.0.3-4, db 10.0.5-6.
  public_cidrs = [for i in range(local.az_count) : cidrsubnet(var.cidr_block, 8, 1 + i)]
  app_cidrs    = [for i in range(local.az_count) : cidrsubnet(var.cidr_block, 8, 1 + local.az_count + i)]
  db_cidrs     = [for i in range(local.az_count) : cidrsubnet(var.cidr_block, 8, 1 + 2 * local.az_count + i)]
}

resource "aws_vpc" "main" {
  cidr_block           = var.cidr_block
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.name}-vpc"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.name}-igw"
  }
}

# ==================== Subnets ====================

# Public: only the ALB lives here
resource "aws_subnet" "public" {
  count = local.az_count

  vpc_id            = aws_vpc.main.id
  cidr_block        = local.public_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name = "${var.name}-public-${var.availability_zones[count.index]}"
    Tier = "public"
  }
}

# Private: ECS tasks
resource "aws_subnet" "app" {
  count = local.az_count

  vpc_id            = aws_vpc.main.id
  cidr_block        = local.app_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name = "${var.name}-app-${var.availability_zones[count.index]}"
    Tier = "app"
  }
}

# Private: RDS primary and standby
resource "aws_subnet" "db" {
  count = local.az_count

  vpc_id            = aws_vpc.main.id
  cidr_block        = local.db_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name = "${var.name}-db-${var.availability_zones[count.index]}"
    Tier = "db"
  }
}

# ==================== Route Tables ====================

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.name}-public"
  }
}

# No default route: private subnets have no internet access (no NAT gateway).
# AWS services are reached through the VPC endpoints below.
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.name}-private"
  }
}

resource "aws_route_table_association" "public" {
  count = local.az_count

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "app" {
  count = local.az_count

  subnet_id      = aws_subnet.app[count.index].id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "db" {
  count = local.az_count

  subnet_id      = aws_subnet.db[count.index].id
  route_table_id = aws_route_table.private.id
}

# ==================== VPC Endpoints ====================

# Gateway endpoint (free). Used to pull image layers from ECR and to upload
# static files to the application bucket.
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.private.id]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # ECR stores image layers in this AWS-owned bucket
        Sid       = "ECRImageLayers"
        Effect    = "Allow"
        Principal = "*"
        Action    = ["s3:GetObject"]
        Resource  = ["arn:aws:s3:::prod-${var.region}-starport-layer-bucket/*"]
      },
      {
        Sid       = "StaticFiles"
        Effect    = "Allow"
        Principal = "*"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket",
          "s3:GetBucketLocation"
        ]
        Resource = [
          "arn:aws:s3:::${var.static_bucket_name}",
          "arn:aws:s3:::${var.static_bucket_name}/*"
        ]
      }
    ]
  })

  tags = {
    Name = "${var.name}-s3"
  }
}

# Interface endpoints required by Fargate tasks without internet access:
# pull images (ecr.api, ecr.dkr), ship logs (logs) and read secrets (secretsmanager).
resource "aws_vpc_endpoint" "interface" {
  for_each = toset(["ecr.api", "ecr.dkr", "logs", "secretsmanager"])

  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.region}.${each.key}"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.app[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = {
    Name = "${var.name}-${replace(each.key, ".", "-")}"
  }
}

resource "aws_security_group" "vpc_endpoints" {
  name_prefix = "${var.name}-vpce-"
  vpc_id      = aws_vpc.main.id
  description = "Interface VPC endpoints"

  ingress {
    description = "HTTPS from the app subnets"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = local.app_cidrs
  }

  tags = {
    Name = "${var.name}-vpce"
  }

  lifecycle {
    create_before_destroy = true
  }
}
