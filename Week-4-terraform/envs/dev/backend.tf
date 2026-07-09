# =============================================================================
# REMOTE BACKEND: State lưu trên S3, lock bằng DynamoDB
# =============================================================================

terraform {
  backend "s3" {
    bucket         = "terraform-state-devops-lab-tien"  # ← Tên bucket từ bootstrap
    key            = "envs/dev/terraform.tfstate"         # ← Path riêng cho dev
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
    profile        = "root-lab"
  }
}
