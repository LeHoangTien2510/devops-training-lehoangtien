module "compute" {
  source = "../../../modules/compute"

  aws_region  = var.aws_region
  aws_profile = var.aws_profile
  environment = var.environment

  cluster_name = var.cluster_name

  node_instance_types = var.node_instance_types
  node_desired_size   = var.node_desired_size
  node_min_size       = var.node_min_size
  node_max_size       = var.node_max_size

  app_image_repository = var.app_image_repository
  app_image_tag        = var.app_image_tag
  app_replicas         = var.app_replicas
  app_ingress_host     = var.app_ingress_host

  demo_app_backend_tag  = var.demo_app_backend_tag
  demo_app_frontend_tag = var.demo_app_frontend_tag

  # REMOTE STATE: Đọc VPC từ tầng network
  network_state_bucket = "terraform-state-devops-lab-tien"
  network_state_key    = "envs/stg/network/terraform.tfstate"
}
