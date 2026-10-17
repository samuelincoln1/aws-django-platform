locals {
  name = "${var.project_name}-${var.environment}"

  tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

data "aws_caller_identity" "current" {}

# Shared secret that CloudFront adds to every origin request. The ALB only
# forwards requests carrying it, so the load balancer cannot be reached directly.
resource "random_password" "origin_verify" {
  length  = 32
  special = false
}

module "vpc" {
  source = "./modules/vpc"

  name               = local.name
  region             = var.aws_region
  cidr_block         = var.vpc_cidr
  availability_zones = var.availability_zones
  static_bucket_name = var.static_bucket_name
}

module "alb" {
  source = "./modules/alb"

  name                       = local.name
  vpc_id                     = module.vpc.vpc_id
  public_subnet_ids          = module.vpc.public_subnet_ids
  app_subnet_cidrs           = module.vpc.app_subnet_cidrs
  certificate_arn            = var.alb_certificate_arn
  origin_verify_header_value = random_password.origin_verify.result
}

module "waf" {
  source = "./modules/waf"
  providers = {
    aws = aws.us_east_1
  }

  name = local.name
}

module "static" {
  source = "./modules/s3"

  bucket_name = var.static_bucket_name
}

module "cdn" {
  source = "./modules/cdn"

  name                       = local.name
  domain_name                = var.domain_name
  certificate_arn            = var.cloudfront_certificate_arn
  route53_zone_id            = var.route53_zone_id
  web_acl_arn                = module.waf.web_acl_arn
  alb_dns_name               = module.alb.alb_dns_name
  origin_verify_header_value = random_password.origin_verify.result

  static_bucket_id                   = module.static.bucket_id
  static_bucket_arn                  = module.static.bucket_arn
  static_bucket_regional_domain_name = module.static.bucket_regional_domain_name
}

module "ecr" {
  source = "./modules/ecr"

  name = local.name
}

module "secrets" {
  source = "./modules/secrets"

  name              = local.name
  django_secret_key = var.django_secret_key
  db_username       = var.db_username
  db_password       = var.db_password
  secrets_version   = var.secrets_version
}

module "rds" {
  source = "./modules/rds"

  name                       = local.name
  vpc_id                     = module.vpc.vpc_id
  subnet_ids                 = module.vpc.db_subnet_ids
  allowed_security_group_ids = [module.ecs.tasks_security_group_id]

  db_name          = "app"
  username         = var.db_username
  password         = var.db_password
  password_version = var.secrets_version
  instance_class   = var.db_instance_class
  multi_az         = var.db_multi_az
}

module "ecs" {
  source = "./modules/ecs"

  name   = local.name
  region = var.aws_region

  vpc_id                          = module.vpc.vpc_id
  subnet_ids                      = module.vpc.app_subnet_ids
  db_subnet_cidrs                 = module.vpc.db_subnet_cidrs
  vpc_endpoints_security_group_id = module.vpc.vpc_endpoints_security_group_id
  s3_prefix_list_id               = module.vpc.s3_prefix_list_id
  alb_security_group_id           = module.alb.security_group_id
  target_group_arn                = module.alb.target_group_arn

  # Only used for the very first deployment: the pipeline registers a new
  # task definition revision with the commit-tagged image on every release.
  container_image = "${module.ecr.repository_url}:bootstrap"
  cpu             = var.task_cpu
  memory          = var.task_memory
  min_capacity    = var.min_tasks
  max_capacity    = var.max_tasks

  static_bucket_arn = module.static.bucket_arn

  environment = {
    DEBUG                   = "false"
    ALLOWED_HOSTS           = var.domain_name
    CSRF_TRUSTED_ORIGINS    = "https://${var.domain_name}"
    DB_HOST                 = module.rds.address
    DB_PORT                 = tostring(module.rds.port)
    DB_NAME                 = module.rds.db_name
    USE_S3                  = "true"
    AWS_STORAGE_BUCKET_NAME = module.static.bucket_id
    AWS_REGION              = var.aws_region
    STATIC_CUSTOM_DOMAIN    = var.domain_name
  }

  secrets = {
    SECRET_KEY  = module.secrets.django_secret_key_arn
    DB_USER     = "${module.secrets.db_credentials_arn}:username::"
    DB_PASSWORD = "${module.secrets.db_credentials_arn}:password::"
  }
  secret_arns = [module.secrets.django_secret_key_arn, module.secrets.db_credentials_arn]
}

module "pipeline" {
  source = "./modules/pipeline"

  name       = local.name
  region     = var.aws_region
  account_id = data.aws_caller_identity.current.account_id

  repository_provider = var.repository_provider
  repository_id       = var.repository_id
  branch_name         = var.branch_name

  ecr_repository_url = module.ecr.repository_url
  ecr_repository_arn = module.ecr.repository_arn

  ecs_cluster_name       = module.ecs.cluster_name
  ecs_service_name       = module.ecs.service_name
  task_definition_family = module.ecs.task_definition_family
  container_name         = module.ecs.container_name
  task_subnet_ids        = module.vpc.app_subnet_ids
  task_security_group_id = module.ecs.tasks_security_group_id
  task_role_arns         = [module.ecs.task_role_arn, module.ecs.execution_role_arn]
}
