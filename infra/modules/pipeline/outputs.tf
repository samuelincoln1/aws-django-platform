output "pipeline_name" {
  description = "Pipeline name"
  value       = aws_codepipeline.main.name
}

output "connection_arn" {
  description = "Source repository connection (approve it in the console)"
  value       = aws_codeconnections_connection.source.arn
}
