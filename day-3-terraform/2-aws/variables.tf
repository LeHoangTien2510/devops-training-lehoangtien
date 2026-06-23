variable "aws_region" {
  type        = string
  description = "AWS Region triển khai hạ tầng"
}

variable "my_ip" {
  type        = string
  description = "IP công cộng hiện tại của bạn để cấu hình SSH (VD: 1.2.3.4/32)"
}
