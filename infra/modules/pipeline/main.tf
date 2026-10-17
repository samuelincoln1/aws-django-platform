# Source (GitHub/Bitbucket/GitLab) -> Build (test + image) -> Deploy (migrate + rolling update)

locals {
  cluster_arn         = "arn:aws:ecs:${var.region}:${var.account_id}:cluster/${var.ecs_cluster_name}"
  service_arn         = "arn:aws:ecs:${var.region}:${var.account_id}:service/${var.ecs_cluster_name}/${var.ecs_service_name}"
  task_definition_arn = "arn:aws:ecs:${var.region}:${var.account_id}:task-definition/${var.task_definition_family}:*"
}

# ==================== Artifacts ====================

resource "aws_s3_bucket" "artifacts" {
  bucket = "${var.name}-pipeline-artifacts-${var.account_id}"
}

resource "aws_s3_bucket_public_access_block" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id

  rule {
    id     = "expire-artifacts"
    status = "Enabled"

    filter {}

    expiration {
      days = 30
    }
  }
}

# ==================== Source connection ====================

# Created in PENDING state: approve it once in the console
# (Developer Tools > Settings > Connections) before the first run.
resource "aws_codeconnections_connection" "source" {
  name          = substr("${var.name}-source", 0, 32)
  provider_type = var.repository_provider
}

# ==================== CodeBuild ====================

data "aws_iam_policy_document" "codebuild_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }
  }
}

resource "aws_cloudwatch_log_group" "codebuild" {
  name              = "/aws/codebuild/${var.name}"
  retention_in_days = 14
}

# --- Build: run the tests and push the image ---

resource "aws_iam_role" "build" {
  name               = "${var.name}-codebuild-build"
  assume_role_policy = data.aws_iam_policy_document.codebuild_assume.json
}

resource "aws_iam_role_policy" "build" {
  name = "build"
  role = aws_iam_role.build.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["logs:CreateLogStream", "logs:PutLogEvents"]
        Resource = "${aws_cloudwatch_log_group.codebuild.arn}:*"
      },
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:GetObjectVersion", "s3:PutObject"]
        Resource = "${aws_s3_bucket.artifacts.arn}/*"
      },
      {
        Effect   = "Allow"
        Action   = ["ecr:GetAuthorizationToken"]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:BatchGetImage",
          "ecr:GetDownloadUrlForLayer",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:PutImage"
        ]
        Resource = var.ecr_repository_arn
      }
    ]
  })
}

resource "aws_codebuild_project" "build" {
  name          = "${var.name}-build"
  description   = "Runs the test suite and pushes the application image to ECR"
  service_role  = aws_iam_role.build.arn
  build_timeout = 20

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type    = "BUILD_GENERAL1_SMALL"
    image           = "aws/codebuild/amazonlinux-x86_64-standard:5.0"
    type            = "LINUX_CONTAINER"
    privileged_mode = true # required to run docker build

    environment_variable {
      name  = "ECR_REPOSITORY_URL"
      value = var.ecr_repository_url
    }
  }

  logs_config {
    cloudwatch_logs {
      group_name  = aws_cloudwatch_log_group.codebuild.name
      stream_name = "build"
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = "ci/buildspec-build.yml"
  }
}

# --- Deploy: migrations as a one-off task, then rolling update ---

resource "aws_iam_role" "deploy" {
  name               = "${var.name}-codebuild-deploy"
  assume_role_policy = data.aws_iam_policy_document.codebuild_assume.json
}

resource "aws_iam_role_policy" "deploy" {
  name = "deploy"
  role = aws_iam_role.deploy.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["logs:CreateLogStream", "logs:PutLogEvents"]
        Resource = "${aws_cloudwatch_log_group.codebuild.arn}:*"
      },
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:GetObjectVersion"]
        Resource = "${aws_s3_bucket.artifacts.arn}/*"
      },
      {
        # These actions do not support resource-level permissions
        Effect   = "Allow"
        Action   = ["ecs:DescribeTaskDefinition", "ecs:RegisterTaskDefinition"]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = ["ecs:RunTask"]
        Resource = local.task_definition_arn
        Condition = {
          ArnEquals = { "ecs:cluster" = local.cluster_arn }
        }
      },
      {
        Effect   = "Allow"
        Action   = ["ecs:DescribeTasks"]
        Resource = "arn:aws:ecs:${var.region}:${var.account_id}:task/${var.ecs_cluster_name}/*"
      },
      {
        Effect   = "Allow"
        Action   = ["ecs:UpdateService", "ecs:DescribeServices"]
        Resource = local.service_arn
      },
      {
        Effect   = "Allow"
        Action   = ["iam:PassRole"]
        Resource = var.task_role_arns
        Condition = {
          StringEquals = { "iam:PassedToService" = "ecs-tasks.amazonaws.com" }
        }
      }
    ]
  })
}

resource "aws_codebuild_project" "deploy" {
  name          = "${var.name}-deploy"
  description   = "Runs database migrations and deploys the new image to ECS"
  service_role  = aws_iam_role.deploy.arn
  build_timeout = 30

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image        = "aws/codebuild/amazonlinux-x86_64-standard:5.0"
    type         = "LINUX_CONTAINER"

    environment_variable {
      name  = "CLUSTER"
      value = var.ecs_cluster_name
    }

    environment_variable {
      name  = "SERVICE"
      value = var.ecs_service_name
    }

    environment_variable {
      name  = "TASK_FAMILY"
      value = var.task_definition_family
    }

    environment_variable {
      name  = "CONTAINER_NAME"
      value = var.container_name
    }

    environment_variable {
      name  = "SUBNETS"
      value = join(",", var.task_subnet_ids)
    }

    environment_variable {
      name  = "SECURITY_GROUP"
      value = var.task_security_group_id
    }
  }

  logs_config {
    cloudwatch_logs {
      group_name  = aws_cloudwatch_log_group.codebuild.name
      stream_name = "deploy"
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = "ci/buildspec-deploy.yml"
  }
}

# ==================== CodePipeline ====================

resource "aws_iam_role" "pipeline" {
  name = "${var.name}-codepipeline"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = { Service = "codepipeline.amazonaws.com" }
      }
    ]
  })
}

resource "aws_iam_role_policy" "pipeline" {
  name = "pipeline"
  role = aws_iam_role.pipeline.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:GetObjectVersion", "s3:PutObject", "s3:GetBucketVersioning"]
        Resource = [aws_s3_bucket.artifacts.arn, "${aws_s3_bucket.artifacts.arn}/*"]
      },
      {
        Effect   = "Allow"
        Action   = ["codebuild:BatchGetBuilds", "codebuild:StartBuild"]
        Resource = [aws_codebuild_project.build.arn, aws_codebuild_project.deploy.arn]
      },
      {
        Effect   = "Allow"
        Action   = ["codeconnections:UseConnection", "codestar-connections:UseConnection"]
        Resource = aws_codeconnections_connection.source.arn
      }
    ]
  })
}

resource "aws_codepipeline" "main" {
  name          = var.name
  role_arn      = aws_iam_role.pipeline.arn
  pipeline_type = "V2"

  # A release is never interrupted halfway through its migrations
  execution_mode = "QUEUED"

  artifact_store {
    location = aws_s3_bucket.artifacts.bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source"]

      configuration = {
        ConnectionArn    = aws_codeconnections_connection.source.arn
        FullRepositoryId = var.repository_id
        BranchName       = var.branch_name
      }
    }
  }

  stage {
    name = "Build"

    action {
      name            = "TestAndBuildImage"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      version         = "1"
      input_artifacts = ["source"]
      namespace       = "Build"

      configuration = {
        ProjectName = aws_codebuild_project.build.name
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name            = "MigrateAndDeploy"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      version         = "1"
      input_artifacts = ["source"]

      configuration = {
        ProjectName = aws_codebuild_project.deploy.name
        EnvironmentVariables = jsonencode([
          {
            name  = "IMAGE_URI"
            value = "#{Build.IMAGE_URI}"
            type  = "PLAINTEXT"
          }
        ])
      }
    }
  }

  depends_on = [aws_iam_role_policy.pipeline]
}
