# =============================================================================
# MODULE COMPUTE: EKS + LB Controller + App
# =============================================================================
# VPC được đọc từ remote_state của tầng network (đã apply trước đó)

# =========================================================
# ĐỌC VPC từ state của tầng network
# =========================================================
data "terraform_remote_state" "network" {
  backend = "s3"
  config = {
    bucket  = var.network_state_bucket
    key     = var.network_state_key
    region  = var.aws_region
    profile = var.aws_profile
  }
}

# =========================================================
# EKS: Cụm Kubernetes
# =========================================================
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  cluster_endpoint_public_access = true

  vpc_id     = data.terraform_remote_state.network.outputs.vpc_id
  subnet_ids = data.terraform_remote_state.network.outputs.private_subnet_ids

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

# =========================================================
# IAM ROLE: AWS Load Balancer Controller
# =========================================================
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

# =========================================================
# HELM: Cài AWS Load Balancer Controller
# =========================================================
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

# =========================================================
# HELM: Deploy ứng dụng
# =========================================================
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

# =========================================================
# HELM: kube-prometheus-stack (cùng default namespace với app)
# =========================================================
resource "helm_release" "kube_prometheus" {
  name       = "kube-prometheus-stack"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  namespace  = "default"

  values = [file("${path.module}/../../observability/kube-prometheus-stack-values.yaml")]
}

# =========================================================
# CONFIGMAP: Dashboard preload cho Grafana
# =========================================================
resource "kubernetes_config_map_v1" "nginx_dashboard" {
  metadata {
    name      = "nginx-dashboard"
    namespace = "default"
    labels = {
      grafana_dashboard = "1"
    }
  }

  data = {
    "nginx-dashboard.json" = file("${path.module}/../../observability/dashboards/nginx-dashboard.json")
  }

  depends_on = [helm_release.kube_prometheus]
}

resource "kubernetes_config_map_v1" "k8s_cluster_dashboard" {
  metadata {
    name      = "k8s-cluster-dashboard"
    namespace = "default"
    labels = {
      grafana_dashboard = "1"
    }
  }

  data = {
    "k8s-cluster-overview.json" = file("${path.module}/../../observability/dashboards/k8s-cluster-overview.json")
  }

  depends_on = [helm_release.kube_prometheus]
}
