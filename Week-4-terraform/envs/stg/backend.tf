# =============================================================================
# REMOTE BACKEND: State lưu trên S3, lock bằng DynamoDB
# =============================================================================

terraform {
  backend "s3" {
    bucket         = "terraform-state-devops-lab-tien"  # ← Tên bucket từ bootstrap
    key            = "envs/stg/terraform.tfstate"         # ← Path riêng cho stg
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
    profile        = "root-lab"
  }
}
