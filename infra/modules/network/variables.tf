# =============================================================================
# BIẾN ĐẦU VÀO - MODULE NETWORK
# =============================================================================

variable "aws_region"  { type = string }
variable "aws_profile" { type = string }
variable "environment" { type = string }

variable "vpc_name" {
  type    = string
  default = "eks-lab-vpc"
}

variable "vpc_cidr"        { type = string }
variable "azs" {
  type    = list(string)
  default = ["us-east-1a", "us-east-1b"]
}
variable "private_subnets" { type = list(string) }
variable "public_subnets"  { type = list(string) }
