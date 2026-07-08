module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = "eks-devops-lab"
  cluster_version = "1.31"

  cluster_endpoint_public_access = true

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets 

  enable_cluster_creator_admin_permissions = true

  eks_managed_node_groups = {
    lab_nodes = {
      min_size     = 1
      max_size     = 3
      desired_size = 2

      # Sử dụng t3a.large (8GB RAM) như đã phân tích để tránh thiếu hụt tài nguyên
      instance_types = ["t3a.large"] 
      capacity_type  = "ON_DEMAND"   
    }
  }

  tags = {
    Environment = "dev"
  }
}