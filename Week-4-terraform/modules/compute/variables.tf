# =============================================================================
# BIẾN ĐẦU VÀO - MODULE COMPUTE
# =============================================================================

variable "aws_region"  { type = string }
variable "aws_profile" { type = string }
variable "environment" { type = string }

variable "cluster_name"    { type = string }
variable "cluster_version" { type = string; default = "1.31" }

# ---------- EKS Node Group ----------
variable "node_instance_types" { type = list(string) }
variable "node_desired_size"   { type = number; default = 2 }
variable "node_min_size"       { type = number; default = 1 }
variable "node_max_size"       { type = number; default = 3 }

# ---------- App (Helm deploy) ----------
variable "app_image_repository" { type = string; default = "nginx" }
variable "app_image_tag"        { type = string; default = "alpine" }
variable "app_replicas"         { type = number; default = 2 }
variable "app_ingress_host"     { type = string; default = "" }

# ---------- Remote State (đọc VPC từ tầng network) ----------
variable "network_state_bucket" {
  description = "S3 bucket chứa state của tầng network"
  type        = string
}

variable "network_state_key" {
  description = "Key trong S3 bucket cho state của network (vd: envs/dev/network/terraform.tfstate)"
  type        = string
}
