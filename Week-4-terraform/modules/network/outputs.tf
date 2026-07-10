# =============================================================================
# OUTPUTS - MODULE NETWORK
# =============================================================================
# Những output này sẽ được module compute đọc qua terraform_remote_state

output "vpc_id" {
  description = "VPC ID để EKS dùng"
  value       = module.vpc.vpc_id
}

output "private_subnet_ids" {
  description = "Private subnets cho EKS node group"
  value       = module.vpc.private_subnets
}

output "public_subnet_ids" {
  description = "Public subnets cho ALB"
  value       = module.vpc.public_subnets
}
