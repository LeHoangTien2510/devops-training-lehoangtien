# =============================================================================
# Terraform: Deploy Jenkins EC2 – Dev Environment
# =============================================================================
# Chạy:
#   cd infra/envs/dev/jenkins
#   terraform init
#   terraform plan
#   terraform apply
# =============================================================================

terraform {
  backend "s3" {
    bucket  = "terraform-state-devops-lab-tien-v2"
    key     = "envs/dev/jenkins/terraform.tfstate"
    region  = "us-east-1"
    profile = "root-lab-2"
  }
}

provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}

# Đọc VPC từ remote state của tầng network (đã apply trước đó)
data "terraform_remote_state" "network" {
  backend = "s3"
  config = {
    bucket  = "terraform-state-devops-lab-tien-v2"
    key     = "envs/dev/network/terraform.tfstate"
    region  = var.aws_region
    profile = var.aws_profile
  }
}

module "jenkins" {
  source = "../../../modules/jenkins"

  name             = "devops"
  environment      = var.environment
  vpc_id           = data.terraform_remote_state.network.outputs.vpc_id
  public_subnet_id = data.terraform_remote_state.network.outputs.public_subnet_ids[0]
  instance_type    = var.jenkins_instance_type
  root_volume_size = var.jenkins_root_volume_size
  key_name         = var.key_name
}

output "jenkins_url" {
  value = module.jenkins.jenkins_url
}

output "ssh_command" {
  value = module.jenkins.ssh_command
}
