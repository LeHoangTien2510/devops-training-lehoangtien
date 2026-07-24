# =============================================================================
# Terraform: Deploy Rancher EC2 – Dev Environment
# =============================================================================
terraform {
  backend "s3" {
    bucket  = "terraform-state-devops-lab-tien-v2"
    key     = "envs/dev/rancher/terraform.tfstate"
    region  = "us-east-1"
    profile = "root-lab-2"
  }
}

provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}

data "terraform_remote_state" "network" {
  backend = "s3"
  config = {
    bucket  = "terraform-state-devops-lab-tien-v2"
    key     = "envs/dev/network/terraform.tfstate"
    region  = var.aws_region
    profile = var.aws_profile
  }
}

module "rancher" {
  source = "../../../modules/rancher"

  name             = "devops"
  environment      = var.environment
  vpc_id           = data.terraform_remote_state.network.outputs.vpc_id
  public_subnet_id = data.terraform_remote_state.network.outputs.public_subnet_ids[0]
  instance_type    = var.rancher_instance_type
  root_volume_size = var.rancher_root_volume_size
  key_name         = var.key_name
}

output "rancher_url" {
  value = module.rancher.rancher_url
}

output "ssh_command" {
  value = module.rancher.ssh_command
}
