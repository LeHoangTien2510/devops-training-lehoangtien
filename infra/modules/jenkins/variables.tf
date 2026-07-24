# =============================================================================
# VARIABLES – MODULE JENKINS
# =============================================================================

variable "name" {
  description = "Tên định danh cho Jenkins resources"
  type        = string
  default     = "devops"
}

variable "environment" {
  description = "Môi trường (dev/stg/prod)"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID nơi đặt Jenkins"
  type        = string
}

variable "public_subnet_id" {
  description = "Public subnet ID cho Jenkins EC2"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.medium"
}

variable "root_volume_size" {
  description = "Dung lượng ổ đĩa root (GB)"
  type        = number
  default     = 30
}

variable "key_name" {
  description = "Key pair name để SSH vào EC2"
  type        = string
  default     = ""
}
