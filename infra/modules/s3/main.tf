# S3 Bucket for Static Files
resource "aws_s3_bucket" "static_files" {
  bucket = var.bucket_name
  
  tags = {
    Name        = "django-app-static-files"
    Environment = "devops-test"
  }
}

# S3 Bucket Public Access Configuration
resource "aws_s3_bucket_public_access_block" "static_files" {
  bucket = aws_s3_bucket.static_files.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# S3 Bucket Policy for Public Read Access (mudar?? ta allowing *)
# resource "aws_s3_bucket_policy" "static_files" {
#   bucket = aws_s3_bucket.static_files.id
#   depends_on = [aws_s3_bucket_public_access_block.static_files]

#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Sid       = "PublicReadGetObject"
#         Effect    = "Allow"
#         Principal = "*"
#         Action    = "s3:GetObject"
#         Resource  = "${aws_s3_bucket.static_files.arn}/*"
#       },
#       {
#         Sid       = "ECSTaskAccess"
#         Effect    = "Allow"
#         Principal = {
#           AWS = "arn:aws:iam::879381266557:role/django-app-service-task-role"
#         }
#         Action = [
#           "s3:GetObject",
#           "s3:PutObject",
#           "s3:DeleteObject",
#           "s3:ListBucket"
#         ]
#         Resource = [
#           "${aws_s3_bucket.static_files.arn}",
#           "${aws_s3_bucket.static_files.arn}/*"
#         ]
#       }
#     ]
#   })
# }
#TROCAR
# resource "aws_s3_bucket_policy" "static_files" {
#   bucket = aws_s3_bucket.static_files.id
#   depends_on = [aws_s3_bucket_public_access_block.static_files]

#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Sid       = "PublicFullAccess"
#         Effect    = "Allow"
#         Principal = "*"
#         Action    = "s3:*"
#         Resource = [
#           "${aws_s3_bucket.static_files.arn}",
#           "${aws_s3_bucket.static_files.arn}/*"
#         ]
#       }
#     ]
#   })
# }

# S3 Bucket Website Configuration
resource "aws_s3_bucket_website_configuration" "static_files" {
  bucket = aws_s3_bucket.static_files.id

  index_document {
    suffix = "index.html"
  }
}

# S3 Bucket CORS Configuration
resource "aws_s3_bucket_cors_configuration" "static_files" {
  bucket = aws_s3_bucket.static_files.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "HEAD"]
    allowed_origins = ["*"]
    max_age_seconds = 3000
  }
}