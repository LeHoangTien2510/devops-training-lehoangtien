# =============================================================================
# OUTPUTS - MODULE COMPUTE
# =============================================================================

output "connect_cluster_command" {
  value = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_name} --profile ${var.aws_profile}"
}

output "cluster_endpoint" { value = module.eks.cluster_endpoint }
output "cluster_name"     { value = module.eks.cluster_name }
output "vpc_id" {
  value = data.terraform_remote_state.network.outputs.vpc_id
}

# =========================================================
# MONITORING OUTPUTS
# =========================================================
output "grafana_admin_password" {
  value     = "admin123"
  sensitive = true
}

output "grafana_access_instructions" {
  value = <<-EOT
  Sau khi apply xong & deploy demo-app chart, truy cập:
  1. Lấy ALB DNS: kubectl get ingress -n default ecommerce-ingress
  2. App:     http://<ALB-DNS>/
  3. Grafana: http://<ALB-DNS>/grafana  (admin / admin123)
  Hoặc port-forward:
    kubectl port-forward -n default svc/kube-prometheus-stack-grafana 3000:80
  EOT
}
