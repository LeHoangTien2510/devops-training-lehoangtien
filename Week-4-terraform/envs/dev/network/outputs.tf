# =============================================================================
# OUTPUTS - Tầng root network
# =============================================================================
# terraform_remote_state chỉ đọc được outputs ở root module
# Nên phải export outputs từ module ra root

output "vpc_id" {
  value = module.network.vpc_id
}

output "private_subnet_ids" {
  value = module.network.private_subnet_ids
}

output "public_subnet_ids" {
  value = module.network.public_subnet_ids
}
