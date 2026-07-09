# =============================================================================
# OUTPUTS: Giá trị trả về sau khi tạo module
# =============================================================================

output "connect_cluster_command" {
  description = "Lệnh kết nối tới cụm EKS"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_name} --profile ${var.aws_profile}"
}

output "cluster_endpoint" {
  description = "API Endpoint của EKS"
  value       = module.eks.cluster_endpoint
}

output "cluster_name" {
  description = "Tên cụm EKS đã tạo"
  value       = module.eks.cluster_name
}

output "vpc_id" {
  description = "ID của VPC"
  value       = module.vpc.vpc_id
}

output "helm_release_name" {
  description = "Tên Helm release của ứng dụng"
  value       = helm_release.app.name
}

output "service_endpoint" {
  description = "Tên Service nội bộ của ứng dụng"
  value       = "nginx-nodeport-service.default.svc.cluster.local"
}
