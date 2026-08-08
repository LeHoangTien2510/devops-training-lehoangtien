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
# IAM ROLE: EBS CSI Driver (cho PVC/EBS volumes)
# =========================================================
module "ebs_csi_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name                              = "eks-ebs-csi-driver"
  attach_ebs_csi_policy                  = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
    }
  }
}

# =========================================================
# HELM: Cài EBS CSI Driver (cho PVC bind EBS volumes)
# =========================================================
resource "helm_release" "ebs_csi" {
  name       = "aws-ebs-csi-driver"
  repository = "https://kubernetes-sigs.github.io/aws-ebs-csi-driver"
  chart      = "aws-ebs-csi-driver"
  namespace  = "kube-system"

  set {
    name  = "controller.serviceAccount.name"
    value = "ebs-csi-controller-sa"
  }
  set {
    name  = "controller.serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.ebs_csi_role.iam_role_arn
  }
}

# StorageClass gp3 (mặc định) – dùng cho PVC của Vault, MySQL, etc.
resource "kubernetes_storage_class_v1" "gp3" {
  metadata {
    name = "gp3"
    annotations = {
      "storageclass.kubernetes.io/is-default-class" = "true"
    }
  }
  storage_provisioner    = "ebs.csi.aws.com"
  volume_binding_mode    = "WaitForFirstConsumer"
  allow_volume_expansion = true
  parameters = {
    type      = "gp3"
    encrypted = "true"
  }
  depends_on = [helm_release.ebs_csi]
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
  wait       = true
  timeout    = 600

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
# CRD: ServiceMonitor – cần trước khi cài NGINX Ingress (ServiceMonitor)
# =========================================================
# Prometheus CRDs không được Helm quản lý → cần cài thủ công
resource "null_resource" "servicemonitor_crd" {
  provisioner "local-exec" {
    command = <<-EOT
      aws eks update-kubeconfig --region ${var.aws_region} --name ${var.cluster_name} --profile ${var.aws_profile}
      kubectl apply --validate=false -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/main/example/prometheus-operator-crd/monitoring.coreos.com_servicemonitors.yaml
    EOT
    interpreter = ["/bin/bash", "-c"]
  }
  depends_on = [module.eks]
}

# =========================================================
# HELM: Cài NGINX Ingress Controller – dùng cho Prometheus metrics analysis
# =========================================================
resource "helm_release" "nginx_ingress" {
  name       = "ingress-nginx"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  namespace  = "ingress-nginx"
  create_namespace = true
  wait       = true
  timeout    = 600

  depends_on = [helm_release.aws_lb_controller, null_resource.servicemonitor_crd]

  set {
    name  = "controller.metrics.enabled"
    value = "true"
  }
  set {
    name  = "controller.metrics.serviceMonitor.enabled"
    value = "true"
  }
  set {
    name  = "controller.ingressClassResource.name"
    value = "nginx"
  }
  set {
    name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-scheme"
    value = "internal"
  }
  set {
    name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-type"
    value = "nlb"
  }
}

# =========================================================
# HELM: Cài cert-manager (TLS)
# =========================================================
resource "helm_release" "cert_manager" {
  name       = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  namespace  = "cert-manager"
  create_namespace = true
  wait       = true
  timeout    = 600

  depends_on = [helm_release.aws_lb_controller]

  set {
    name  = "installCRDs"
    value = "true"
  }
}

# =========================================================
# HELM: Cài ArgoCD (GitOps CD)
# =========================================================
resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  namespace  = "argocd"
  create_namespace = true
  wait       = true
  timeout    = 600

  depends_on = [helm_release.aws_lb_controller]

  set {
    name  = "server.service.type"
    value = "ClusterIP"
  }
}

# =========================================================
# HELM: Cài Argo Rollouts (Blue-Green + Canary)
# =========================================================
resource "helm_release" "argo_rollouts" {
  name             = "argo-rollouts"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-rollouts"
  namespace        = "argo-rollouts"
  create_namespace = true
  wait             = true
  timeout          = 300

  depends_on = [helm_release.aws_lb_controller]
}

# =========================================================
# HELM: Cài HashiCorp Vault (Secret Management)
# =========================================================
# Khi destroy: force-delete namespace trước để tránh deadlock PVC/NLB
resource "null_resource" "vault_cleanup" {
  triggers = {
    helm_release = helm_release.vault.id
  }
  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
      kubectl delete namespace vault --force --grace-period=0 --timeout=30s 2>/dev/null || true
      kubectl get ns vault -o json 2>/dev/null | python3 -c "import json,sys; d=json.load(sys.stdin); d['spec']['finalizers']=[]; print(json.dumps(d))" | kubectl replace --raw "/api/v1/namespaces/vault/finalize" -f - 2>/dev/null || true
    EOT
  }
}

resource "helm_release" "vault" {
  name             = "vault"
  repository       = "https://helm.releases.hashicorp.com"
  chart            = "vault"
  namespace        = "vault"
  create_namespace = true
  wait             = true
  timeout          = 600

  depends_on = [helm_release.aws_lb_controller]

  values = [
    file("${path.module}/../../vault/vault-values.yaml")
  ]
}

# =========================================================
# HELM: kube-prometheus-stack (Prometheus + Grafana)
# =========================================================
resource "helm_release" "kube_prometheus" {
  name       = "kube-prometheus-stack"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  namespace  = "demo-app"
  create_namespace = true
  wait       = true
  timeout    = 600

  depends_on = [helm_release.aws_lb_controller]

  values = [file("${path.module}/../../observability/kube-prometheus-stack-values.yaml")]
}

# =========================================================
# CONFIGMAP: Dashboard preload cho Grafana
# =========================================================
resource "kubernetes_config_map_v1" "nginx_dashboard" {
  metadata {
    name      = "nginx-dashboard"
    namespace = "demo-app"
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
    namespace = "demo-app"
    labels = {
      grafana_dashboard = "1"
    }
  }
  data = {
    "k8s-cluster-overview.json" = file("${path.module}/../../observability/dashboards/k8s-cluster-overview.json")
  }
  depends_on = [helm_release.kube_prometheus]
}
