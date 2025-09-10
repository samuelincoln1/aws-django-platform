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
