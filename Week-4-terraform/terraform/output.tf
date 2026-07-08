# Xuất lệnh kết nối K8s để bạn chỉ cần copy-paste vào Terminal
output "connect_cluster_command" {
  description = "Lệnh để cấu hình kubectl kết nối tới cụm EKS"
  value       = "aws eks update-kubeconfig --region us-east-1 --name ${module.eks.cluster_name} --profile root-lab"
}

# Xuất vùng mạng EKS Endpoint để kiểm tra
output "cluster_endpoint" {
  description = "Endpoint API của cụm EKS Master"
  value       = module.eks.cluster_endpoint
}
