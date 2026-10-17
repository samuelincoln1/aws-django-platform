# Instantiated with the us-east-1 provider: CLOUDFRONT-scoped web ACLs only exist there
terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}
