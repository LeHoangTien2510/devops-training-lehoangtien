variable "aws_region" {
  description = "Region chạy hạ tầng AWS"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Tên môi trường triển khai"
  type        = string
  default     = "dev"
}

variable "cluster_name" {
  description = "Tên của cụm EKS"
  type        = string
  default     = "eks-devops-lab"
}

variable "vpc_cidr" {
  description = "Dải mạng CIDR cho VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnets" {
  description = "Danh sách dải mạng Public Subnets"
  type        = list(string)
  default     = ["10.0.101.0/24", "10.0.102.0/24"]
}

variable "private_subnets" {
  description = "Danh sách dải mạng Private Subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "node_instance_type" {
  description = "Loại máy ảo EC2 làm Worker Node"
  type        = string
  default     = "t3a.large"
}
