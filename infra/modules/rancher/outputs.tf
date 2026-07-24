output "public_ip" {
  value = aws_eip.rancher.public_ip
}

output "rancher_url" {
  value = "https://${aws_eip.rancher.public_ip}.sslip.io"
}

output "ssh_command" {
  value = "ssh -i ~/.ssh/${var.key_name} ubuntu@${aws_eip.rancher.public_ip}"
}
