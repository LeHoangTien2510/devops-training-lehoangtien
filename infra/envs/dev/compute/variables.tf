variable "aws_region"  { type = string }
variable "aws_profile" { type = string }
variable "environment" { type = string }

variable "cluster_name" { type = string }

variable "node_instance_types" { type = list(string) }
variable "node_desired_size"   { type = number }
variable "node_min_size"       { type = number }
variable "node_max_size"       { type = number }

variable "app_image_repository" { type = string }
variable "app_image_tag"        { type = string }
variable "app_replicas"         { type = number }
variable "app_ingress_host"     { type = string }


