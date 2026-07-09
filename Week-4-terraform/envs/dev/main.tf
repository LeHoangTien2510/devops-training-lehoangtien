# =============================================================================
# ENV: DEV - Gọi module k8s-app với config cho môi trường Dev
# =============================================================================

module "k8s_app" {
  source = "../../modules/k8s-app"

  aws_region  = var.aws_region
  aws_profile = var.aws_profile

  environment  = var.environment
  cluster_name = var.cluster_name

  vpc_cidr        = var.vpc_cidr
  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets

  node_instance_types = var.node_instance_types
  node_desired_size   = var.node_desired_size
  node_min_size       = var.node_min_size
  node_max_size       = var.node_max_size
}
