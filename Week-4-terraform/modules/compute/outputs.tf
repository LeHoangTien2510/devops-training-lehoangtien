# =============================================================================
# OUTPUTS - MODULE COMPUTE
# =============================================================================

output "connect_cluster_command" {
  value = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_name} --profile ${var.aws_profile}"
}

output "cluster_endpoint" { value = module.eks.cluster_endpoint }
output "cluster_name"     { value = module.eks.cluster_name }
output "helm_release_name" { value = helm_release.app.name }
output "vpc_id" {
  value = data.terraform_remote_state.network.outputs.vpc_id
}
