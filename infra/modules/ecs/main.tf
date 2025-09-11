# ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = var.cluster_name

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name        = var.cluster_name
    Environment = var.environment
  }
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "django_app" {
  name              = "/ecs/${var.service_name}"
  retention_in_days = 30

  tags = {
    Name        = "${var.service_name}-logs"
    Environment = var.environment
  }
}

# ECS Task Execution Role
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${var.service_name}-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.service_name}-execution-role"
    Environment = var.environment
  }
}

# Attach policy to execution role
resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy" "ecs_secrets_policy" {
  name = "${var.service_name}-secrets-policy"
  role = aws_iam_role.ecs_task_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = [
          "arn:aws:secretsmanager:us-east-1:*:secret:django-app/*"
        ]
      }
    ]
  })
}

# Security Group for ECS Tasks
resource "aws_security_group" "ecs_tasks" {
  name_prefix = "${var.service_name}-tasks-"
  vpc_id      = var.vpc_id
  description = "Security group for ECS tasks"

  # Allow traffic from ALB on port 8000
  ingress {
    description     = "HTTP from ALB"
    from_port       = 8000
    to_port         = 8000
    protocol        = "tcp"
    security_groups = [var.alb_security_group_id]
  }

  # HTTPS to VPC Endpoints (ECR, CloudWatch, etc)
  egress {
    description     = "HTTPS to VPC Endpoints"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [var.vpc_endpoints_security_group_id]
  }

  # HTTP to VPC Endpoints
  egress {
    description     = "HTTP to VPC Endpoints"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [var.vpc_endpoints_security_group_id]
  }

  # HTTPS to S3 via Prefix List
  egress {
    description     = "HTTPS to S3 via Prefix List"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    prefix_list_ids = [data.aws_prefix_list.s3.id]
  }

  # Allow outbound traffic to RDS
  egress {
    description = "PostgreSQL to RDS"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_block]
  }

  # Allow outbound traffic to DNS
  egress {
    description = "DNS resolution"
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.service_name}-tasks-sg"
    Environment = var.environment
  }

  lifecycle {
    create_before_destroy = true
  }
}

# ECS Task Definition
resource "aws_ecs_task_definition" "django_app" {
  family                   = var.service_name
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.cpu
  memory                   = var.memory
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name  = "django-app"
      image = var.container_image
      user  = "app:app"

      portMappings = [
        {
          containerPort = 8000
          protocol      = "tcp"
        }
      ]

      # environment = [
      #   {
      #     name  = "DEBUG"
      #     value = var.django_debug
      #   },
      #   {
      #     name  = "ALLOWED_HOSTS"
      #     value = var.django_allowed_hosts
      #   },
      #   {
      #     name  = "DB_HOST"
      #     value = var.db_host
      #   },
      #   {
      #     name  = "DB_PORT"
      #     value = var.db_port
      #   },
      #   {
      #     name  = "DB_NAME"
      #     value = var.db_name
      #   },
      #   {
      #     name  = "USE_S3"
      #     value = var.use_s3
      #   },
      #   {
      #     name  = "AWS_STORAGE_BUCKET_NAME"
      #     value = var.aws_storage_bucket_name
      #   },
      #   {
      #     name  = "AWS_REGION"
      #     value = var.aws_region
      #   }
      # ]

      environment = [
        {
          name  = "DEBUG"
          value = "False"
        },
        {
          name  = "DATABASE_URL"
          value = "sqlite:///db.sqlite3"
        },
        {
          name  = "ALLOWED_HOSTS"
          value = "*"
        },
        {
          name  = "USE_S3"
          value = "false"
        }
      ]

      # secrets = [
      #   {
      #     name      = "SECRET_KEY"
      #     valueFrom = var.secret_arns.secret_key
      #   },
      #   {
      #     name      = "DB_USER"
      #     valueFrom = "${var.secret_arns.db_credentials}:username::"
      #   },
      #   {
      #     name      = "DB_PASSWORD"
      #     valueFrom = "${var.secret_arns.db_credentials}:password::"
      #   }
      # ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.django_app.name
          "awslogs-region"        = "us-east-1"
          "awslogs-stream-prefix" = "ecs"
        }
      }

      essential = true

      healthCheck = {
        command = [
          "CMD-SHELL",
          "curl -f http://localhost:8000/healthz/ || exit 1"
        ]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }
    }
  ])

  tags = {
    Name        = "${var.service_name}-task-definition"
    Environment = var.environment
  }
}

# ECS Service
resource "aws_ecs_service" "django_app" {
  name            = var.service_name
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.django_app.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = var.private_subnet_ids
    security_groups = [aws_security_group.ecs_tasks.id]
  }

  load_balancer {
    target_group_arn = var.alb_target_group_arn
    container_name   = "django-app"
    container_port   = 8000
  }

  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 50

  depends_on = [aws_iam_role_policy_attachment.ecs_task_execution_role_policy]

  tags = {
    Name        = var.service_name
    Environment = var.environment
  }
}

# Data source para S3 Prefix List - ADICIONAR
data "aws_prefix_list" "s3" {
  name = "com.amazonaws.us-east-1.s3"
}
