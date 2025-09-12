resource "aws_s3_bucket" "static_files" {
  bucket = var.bucket_name
  
  tags = {
    Name        = "django-app-static-files"
    Environment = "devops-test"
  }
}

resource "aws_s3_bucket_public_access_block" "static_files" {
  bucket = aws_s3_bucket.static_files.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}


resource "aws_s3_bucket_website_configuration" "static_files" {
  bucket = aws_s3_bucket.static_files.id

  index_document {
    suffix = "index.html"
  }
}

resource "aws_s3_bucket_cors_configuration" "static_files" {
  bucket = aws_s3_bucket.static_files.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "HEAD"]
    allowed_origins = ["*"]
    max_age_seconds = 3000
  }
}