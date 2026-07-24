# =============================================================================
# BOOTSTRAP: Tạo S3 bucket + DynamoDB table cho Terraform remote state
# CHẠY 1 LẦN DUY NHẤT trước khi dùng các env
# =============================================================================

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region  = "us-east-1"
  profile = "root-lab-2"
}

# S3 bucket lưu state
resource "aws_s3_bucket" "terraform_state" {
  bucket = "terraform-state-devops-lab-tien-v2"
  #       ^^^ TÊN PHẢI UNIQUE TOÀN CẦU, đổi theo tên bạn
}

# Bật versioning để có thể rollback state
resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Mã hóa state
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Chặn public access
resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket                  = aws_s3_bucket.terraform_state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# DynamoDB table để lock state
resource "aws_dynamodb_table" "terraform_locks" {
  name         = "terraform-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}
