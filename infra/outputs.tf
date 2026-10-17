output "app_url" {
  description = "Public URL of the application"
  value       = "https://${var.domain_name}"
}

output "cloudfront_domain_name" {
  description = "Point the application domain here (CNAME / alias) when Route 53 is not managed by this project"
  value       = module.cdn.domain_name
}

output "ecr_repository_url" {
  description = "ECR repository for the application image"
  value       = module.ecr.repository_url
}

output "pipeline_name" {
  description = "CodePipeline that builds and deploys the application"
  value       = module.pipeline.pipeline_name
}

output "source_connection_arn" {
  description = "Connection to the source repository. Must be approved once in the AWS console"
  value       = module.pipeline.connection_arn
}

output "ecs_cluster_name" {
  description = "ECS cluster name"
  value       = module.ecs.cluster_name
}

output "rds_endpoint" {
  description = "Private endpoint of the PostgreSQL database"
  value       = "${module.rds.address}:${module.rds.port}"
}
