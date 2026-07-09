# =============================================================================
# BIẾN CHO ENV - Khai báo để terraform.tfvars map vào
# =============================================================================

variable "aws_region"  { type = string }
variable "aws_profile" { type = string }

variable "environment"  { type = string }
variable "cluster_name" { type = string }

variable "vpc_cidr"        { type = string }
variable "private_subnets" { type = list(string) }
variable "public_subnets"  { type = list(string) }

variable "node_instance_types" { type = list(string) }
variable "node_desired_size"   { type = number }
variable "node_min_size"       { type = number }
variable "node_max_size"       { type = number }
