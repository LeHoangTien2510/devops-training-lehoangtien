terraform {
  backend "s3" {
    bucket         = "terraform-state-devops-lab-tien"
    key            = "envs/dev/compute/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
    profile        = "root-lab"
  }
}
