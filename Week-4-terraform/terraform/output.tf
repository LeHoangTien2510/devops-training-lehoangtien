output "connect_cluster_command" {
  description = "Lệnh gõ trên terminal máy bạn để kết nối trực tiếp tới cụm EKS"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_name} --profile root-lab"
}

output "cluster_endpoint" {
  description = "Đường dẫn API Endpoint của cụm EKS Master"
  value       = module.eks.cluster_endpoint
}

output "vpc_id" {
  description = "ID của mạng VPC vừa tạo"
  value       = module.vpc.vpc_id
}
