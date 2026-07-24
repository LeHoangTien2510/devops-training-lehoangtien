# =============================================================================
# VARIABLES – MODULE RANCHER
# =============================================================================

variable "name" {
  description = "Tên định danh"
  type        = string
  default     = "devops"
}

variable "environment" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "public_subnet_id" {
  type = string
}

variable "instance_type" {
  type    = string
  default = "t3.large"     # Rancher khuyến nghị 4GB RAM
}

variable "root_volume_size" {
  type    = number
  default = 50
}

variable "key_name" {
  type    = string
  default = ""
}
