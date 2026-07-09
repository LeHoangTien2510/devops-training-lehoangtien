# =============================================================================
# BIẾN ĐẦU VÀO CỦA MODULE K8S-APP
# =============================================================================

variable "aws_region" {
  description = "AWS region để deploy"
  type        = string
}

variable "aws_profile" {
  description = "AWS CLI profile để xác thực"
  type        = string
}

variable "environment" {
  description = "Tên môi trường (dev, stg, prod)"
  type        = string
}

variable "cluster_name" {
  description = "Tên cụm EKS"
  type        = string
}

variable "cluster_version" {
  description = "Phiên bản Kubernetes"
  type        = string
  default     = "1.33"
}

# ---------- VPC ----------
variable "vpc_name" {
  description = "Tên hiển thị cho VPC"
  type        = string
  default     = "eks-lab-vpc"
}

variable "vpc_cidr" {
  description = "CIDR cho VPC"
  type        = string
}

variable "azs" {
  description = "Danh sách Availability Zones"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "private_subnets" {
  description = "CIDR cho private subnets"
  type        = list(string)
}

variable "public_subnets" {
  description = "CIDR cho public subnets"
  type        = list(string)
}

# ---------- EKS Node Group ----------
variable "node_instance_types" {
  description = "Loại máy EC2 cho worker node"
  type        = list(string)
}

variable "node_desired_size" {
  description = "Số node mong muốn"
  type        = number
  default     = 2
}

variable "node_min_size" {
  description = "Số node tối thiểu"
  type        = number
  default     = 1
}

variable "node_max_size" {
  description = "Số node tối đa"
  type        = number
  default     = 3
}

# ---------- App (Helm deploy) ----------
variable "app_image_repository" {
  description = "Docker image repository cho app"
  type        = string
  default     = "nginx"
}

variable "app_image_tag" {
  description = "Docker image tag"
  type        = string
  default     = "alpine"
}

variable "app_replicas" {
  description = "Số lượng pod replica"
  type        = number
  default     = 2
}

variable "app_ingress_host" {
  description = "Domain host cho Ingress (để trống nếu dùng ALB DNS mặc định)"
  type        = string
  default     = ""
}
