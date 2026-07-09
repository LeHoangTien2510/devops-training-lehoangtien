# =============================================================================
# VPC: Mạng ảo cho toàn bộ hạ tầng
# =============================================================================
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = var.vpc_name
  cidr = var.vpc_cidr

  azs             = var.azs
  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets

  enable_nat_gateway = true
  single_nat_gateway = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
  }

  tags = {
    Environment = var.environment
    Terraform   = "true"
  }
}

# =============================================================================
# EKS: Cụm Kubernetes
# =============================================================================
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  cluster_endpoint_public_access = true

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  enable_cluster_creator_admin_permissions = true

  eks_managed_node_groups = {
    lab_nodes = {
      min_size     = var.node_min_size
      max_size     = var.node_max_size
      desired_size = var.node_desired_size

      instance_types = var.node_instance_types
      capacity_type  = "ON_DEMAND"
    }
  }

  tags = {
    Environment = var.environment
  }
}

# =============================================================================
# IAM ROLE: AWS Load Balancer Controller
# =============================================================================
module "lb_controller_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name                              = "eks-aws-load-balancer-controller"
  attach_load_balancer_controller_policy = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-load-balancer-controller"]
    }
  }
}

# =============================================================================
# HELM: Cài AWS Load Balancer Controller vào cụm
# =============================================================================
resource "helm_release" "aws_lb_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"

  set {
    name  = "clusterName"
    value = module.eks.cluster_name
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.lb_controller_role.iam_role_arn
  }
}

# =============================================================================
# HELM: Deploy ứng dụng lên cụm (Deployment + Service + Ingress)
# =============================================================================
resource "helm_release" "app" {
  name      = "nginx-app"
  chart     = "${path.module}/chart"
  namespace = "default"

  depends_on = [helm_release.aws_lb_controller]

  set {
    name  = "image.repository"
    value = var.app_image_repository
  }
  set {
    name  = "image.tag"
    value = var.app_image_tag
  }
  set {
    name  = "replicas"
    value = var.app_replicas
  }
  set {
    name  = "ingress.host"
    value = var.app_ingress_host
  }
}
