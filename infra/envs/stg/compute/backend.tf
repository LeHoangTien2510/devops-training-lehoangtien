terraform {
  backend "s3" {
    bucket         = "terraform-state-devops-lab-tien-v2"
    key            = "envs/stg/compute/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
    profile        = "root-lab-2"
  }
}
