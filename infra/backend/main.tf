terraform {
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

# Bucket S3 para armazenar o estado do Terraform
resource "aws_s3_bucket" "terraform_state" {
  bucket = "samuellincoln-terraform-state-devops-test"

  tags = {
    Name        = "Terraform State Bucket"
    Environment = "devops-test"
  }
}

# Configuração de versionamento do bucket
resource "aws_s3_bucket_versioning" "terraform_state_versioning" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Configuração de criptografia do bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state_encryption" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Bloqueio de acesso público ao bucket
resource "aws_s3_bucket_public_access_block" "terraform_state_pab" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Tabela DynamoDB para lock do estado
resource "aws_dynamodb_table" "terraform_state_lock" {
  name           = "terraform-state-locking-devops-test"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name        = "Terraform State Lock Table"
    Environment = "devops-test"
  }
}

# Outputs para referência
output "s3_bucket_name" {
  description = "Nome do bucket S3 para o estado do Terraform"
  value       = aws_s3_bucket.terraform_state.bucket
}

output "dynamodb_table_name" {
  description = "Nome da tabela DynamoDB para lock do estado"
  value       = aws_dynamodb_table.terraform_state_lock.name
}
