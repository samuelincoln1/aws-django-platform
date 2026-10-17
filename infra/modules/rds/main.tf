locals {
  engine_major_version = split(".", var.engine_version)[0]
}

resource "aws_security_group" "rds" {
  name_prefix = "${var.name}-rds-"
  vpc_id      = var.vpc_id
  description = "PostgreSQL: access from the application tasks only"

  ingress {
    description     = "PostgreSQL from the ECS tasks"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = var.allowed_security_group_ids
  }

  tags = {
    Name = "${var.name}-rds"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_db_subnet_group" "main" {
  name       = var.name
  subnet_ids = var.subnet_ids
}

resource "aws_db_parameter_group" "postgresql" {
  name   = "${var.name}-postgres${local.engine_major_version}"
  family = "postgres${local.engine_major_version}"

  parameter {
    name         = "shared_preload_libraries"
    value        = "pg_stat_statements"
    apply_method = "pending-reboot"
  }

  # Log schema changes and slow queries (>1s), not every statement
  parameter {
    name  = "log_statement"
    value = "ddl"
  }

  parameter {
    name  = "log_min_duration_statement"
    value = "1000"
  }

  parameter {
    name  = "log_connections"
    value = "1"
  }

  parameter {
    name  = "log_disconnections"
    value = "1"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_role" "enhanced_monitoring" {
  name = "${var.name}-rds-monitoring"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = { Service = "monitoring.rds.amazonaws.com" }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "enhanced_monitoring" {
  role       = aws_iam_role.enhanced_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

# Created before the instance so the retention period applies from the start
resource "aws_cloudwatch_log_group" "postgresql" {
  name              = "/aws/rds/instance/${var.name}/postgresql"
  retention_in_days = 14
}

resource "aws_db_instance" "postgresql" {
  identifier     = var.name
  engine         = "postgres"
  engine_version = var.engine_version
  instance_class = var.instance_class

  db_name             = var.db_name
  username            = var.username
  password_wo         = var.password
  password_wo_version = var.password_version

  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type          = "gp3"
  storage_encrypted     = true

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = false
  multi_az               = var.multi_az
  parameter_group_name   = aws_db_parameter_group.postgresql.name

  enabled_cloudwatch_logs_exports = ["postgresql"]

  backup_retention_period = 7
  backup_window           = "03:00-04:00"
  maintenance_window      = "sun:04:30-sun:05:30"
  copy_tags_to_snapshot   = true

  auto_minor_version_upgrade  = true
  allow_major_version_upgrade = false

  monitoring_interval                   = 60
  monitoring_role_arn                   = aws_iam_role.enhanced_monitoring.arn
  performance_insights_enabled          = true
  performance_insights_retention_period = 7

  deletion_protection       = var.deletion_protection
  skip_final_snapshot       = false
  final_snapshot_identifier = "${var.name}-final"

  depends_on = [
    aws_cloudwatch_log_group.postgresql,
    aws_iam_role_policy_attachment.enhanced_monitoring,
  ]
}
