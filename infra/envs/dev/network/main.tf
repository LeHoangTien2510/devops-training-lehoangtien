module "network" {
  source = "../../../modules/network"

  aws_region  = var.aws_region
  aws_profile = var.aws_profile
  environment = var.environment

  vpc_cidr        = var.vpc_cidr
  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets
}
