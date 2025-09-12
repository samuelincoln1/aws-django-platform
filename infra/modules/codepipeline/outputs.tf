output "pipeline_name" {
  description = "Pipeline name"
  value       = aws_codepipeline.main_pipeline.name
}

output "pipeline_arn" {
  description = "Pipeline ARN"
  value       = aws_codepipeline.main_pipeline.arn
}

output "codebuild_project_name" {
  description = "CodeBuild project name"
  value       = aws_codebuild_project.build_project.name
}

output "codestar_connection_arn" {
  description = "CodeStar connection ARN"
  value       = aws_codestarconnections_connection.bitbucket.arn
}

output "artifacts_bucket_name" {
  description = "Artifacts bucket name"
  value       = aws_s3_bucket.codepipeline_artifacts.bucket
}