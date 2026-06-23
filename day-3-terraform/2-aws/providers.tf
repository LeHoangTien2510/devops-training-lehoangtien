provider "aws" {
  region = var.aws_region
  default_tags {
    tags = {
      Project = "devops-training"
      Owner   = "TienLeHoang" 
    }
  }
}
