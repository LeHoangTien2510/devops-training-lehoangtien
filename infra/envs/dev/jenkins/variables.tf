variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "aws_profile" {
  type    = string
  default = "root-lab-2"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "jenkins_instance_type" {
  type    = string
  default = "t3.medium"
}

variable "jenkins_root_volume_size" {
  type    = number
  default = 30
}

variable "key_name" {
  description = "Key pair để SSH vào EC2"
  type        = string
  default     = ""
}
