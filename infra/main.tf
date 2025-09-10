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

# ==================== OUTPUTS ====================

output "vpc_info" {
  description = "Information of the created VPC"
  value = {
    vpc_id     = module.vpc.vpc_id
    cidr_block = module.vpc.vpc_cidr_block
  }
}

output "public_subnets" {
  description = "Public subnets for ALB"
  value = {
    subnet_ids = module.vpc.public_subnet_ids
    az1_id     = module.vpc.public_subnet_az1_id
    az2_id     = module.vpc.public_subnet_az2_id
  }
}

output "private_ecs_subnets" {
  description = "Private subnets for ECS Fargate"
  value = {
    subnet_ids = module.vpc.private_ecs_subnet_ids
    az1_id     = module.vpc.private_ecs_subnet_az1_id
    az2_id     = module.vpc.private_ecs_subnet_az2_id
  }
}

output "private_rds_subnets" {
  description = "Private subnets for RDS"
  value = {
    subnet_ids = module.vpc.private_rds_subnet_ids
    primary_id = module.vpc.private_rds_subnet_az1_id
    standby_id = module.vpc.private_rds_subnet_az2_id
  }
}

# Outputs of the ALB
output "alb_info" {
  description = "Information of the Application Load Balancer"
  value = {
    dns_name         = module.alb.alb_dns_name
    url              = module.alb.alb_url
    target_group_arn = module.alb.target_group_arn
  }
}
