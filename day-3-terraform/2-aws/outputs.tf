output "public_ip" {
  value       = aws_eip.web_eip.public_ip
  description = "Dia chi Elastic IP cua Web Server"
}

output "instance_id" {
  value       = aws_instance.web.id
  description = "ID cua EC2 Instance"
}
