# ============================================
# VARIABLES - Secrets (sensitive)
# ============================================
variable "django_secret_key" {
  description = "Django SECRET_KEY"
  type        = string
  sensitive   = true
}

variable "db_user" {
  description = "Database user"
  type        = string
  default     = "app"
}

variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}

terraform {
  backend "s3" {
    bucket         = "samuellincoln-terraform-state-devops-test"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-locking-devops-test"
    encrypt        = true
  }



  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"

}

module "vpc" {
  source               = "./modules/vpc"
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  availability_zone_1        = "us-east-1a"
  public_subnet_cidr_block_1 = "10.0.1.0/24"
  private_subnet_ecs_cidr_1  = "10.0.3.0/24"
  private_subnet_rds_cidr_1  = "10.0.5.0/24"

  availability_zone_2        = "us-east-1b"
  public_subnet_cidr_block_2 = "10.0.2.0/24"
  private_subnet_ecs_cidr_2  = "10.0.4.0/24"
  private_subnet_rds_cidr_2  = "10.0.6.0/24"

  map_public_ip_on_launch = false
}

module "alb" {
  source = "./modules/alb"
  vpc_id            = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids

  # Initially without SSL certificate (only HTTP)
  # certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/12345678-1234-1234-1234-123456789012"
}

module "ecr" {
  source = "./modules/ecr"
}


module "secrets" {
  source = "./modules/secrets"

  django_secret_key = var.django_secret_key
  db_user          = var.db_user
  db_password      = var.db_password
}

module "s3" {
  source      = "./modules/s3"
  bucket_name = "samuel-lincoln-django-app-static"
  aws_region  = "us-east-1"
}



module "rds" {
  source = "./modules/rds"

  environment = "devops-test"
  vpc_id      = module.vpc.vpc_id

  private_subnet_ids = module.vpc.private_rds_subnet_ids
  
  vpc_cidr_block = module.vpc.vpc_cidr_block
  
  db_name     = "app"
  db_username = var.db_user
  db_password = var.db_password
  
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  max_allocated_storage  = 100
  multi_az              = false
  deletion_protection   = false
  skip_final_snapshot   = true
  
  # Monitoring
  monitoring_interval                   = 60
  performance_insights_enabled          = true
  performance_insights_retention_period = 7
}

module "ecs" {
  source = "./modules/ecs"

  cluster_name          = "django-app-cluster"
  service_name          = "django-app-service"
  environment           = "devops-test"
  
  vpc_id                = module.vpc.vpc_id
  vpc_cidr_block        = module.vpc.vpc_cidr_block
  private_subnet_ids    = module.vpc.private_ecs_subnet_ids
  alb_target_group_arn  = module.alb.target_group_arn
  alb_security_group_id = module.alb.alb_security_group_id
  vpc_endpoints_security_group_id = module.vpc.vpc_endpoints_security_group_id 
  container_image       = "${module.ecr.repository_url}:latest"


  django_debug          = "False"
  django_allowed_hosts = ".${module.alb.alb_dns_name},localhost,127.0.0.1"
  db_host               = module.rds.db_endpoint
  db_port               = module.rds.db_port
  db_name               = module.rds.db_name
  use_s3                = "true"
  aws_storage_bucket_name = module.s3.bucket_name
  s3_bucket_arn           = module.s3.bucket_arn
  aws_region      = "us-east-1"

  desired_count         = 2
  cpu                   = 2048
  memory                = 4096
  secret_arns           = module.secrets.secret_arns
 
}








# ==================== OUTPUTS ====================

# # VPC Outputs
# output "vpc_info" {
#   description = "Information of the created VPC"
#   value = {
#     vpc_id     = module.vpc.vpc_id
#     cidr_block = module.vpc.vpc_cidr_block
#   }
# }

# output "public_subnets" {
#   description = "Public subnets for ALB"
#   value = {
#     subnet_ids = module.vpc.public_subnet_ids
#     az1_id     = module.vpc.public_subnet_az1_id
#     az2_id     = module.vpc.public_subnet_az2_id
#   }
# }

# output "private_ecs_subnets" {
#   description = "Private subnets for ECS Fargate"
#   value = {
#     subnet_ids = module.vpc.private_ecs_subnet_ids
#     az1_id     = module.vpc.private_ecs_subnet_az1_id
#     az2_id     = module.vpc.private_ecs_subnet_az2_id
#   }
# }

# output "private_rds_subnets" {
#   description = "Private subnets for RDS"
#   value = {
#     subnet_ids = module.vpc.private_rds_subnet_ids
#     primary_id = module.vpc.private_rds_subnet_az1_id
#     standby_id = module.vpc.private_rds_subnet_az2_id
#   }
# }

# # ALB Outputs
# output "alb_info" {
#   description = "Information of the Application Load Balancer"
#   value = {
#     dns_name         = module.alb.alb_dns_name
#     url              = module.alb.alb_url
#     target_group_arn = module.alb.target_group_arn
#   }
# }

# # ECR Outputs
# output "ecr_info" {
#   description = "Informações do ECR"
#   value = {
#     repository_url  = module.ecr.repository_url
#     repository_name = module.ecr.repository_name
#     registry_id     = module.ecr.registry_id
#   }
# }

# RDS OUTPUTS
output "rds_info" {
  description = "RDS PostgreSQL database information"
  value = {
    endpoint    = module.rds.db_endpoint
    port        = module.rds.db_port
    database    = module.rds.db_name
    instance_id = module.rds.db_instance_id
  }
}

output "rds_connection_info" {
  description = "Database connection details for application"
  value       = module.rds.db_connection_info
  sensitive   = false
}
