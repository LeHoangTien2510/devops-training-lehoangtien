variable "aws_region"  { default = "us-east-1" }
variable "aws_profile" { default = "root-lab-2" }
variable "environment" { default = "dev" }

variable "rancher_instance_type"    { default = "t3.medium" }
variable "rancher_root_volume_size" { default = 50 }
variable "key_name"                 { default = "" }
