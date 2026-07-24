# =============================================================================
# OUTPUTS – MODULE JENKINS
# =============================================================================

output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.jenkins.id
}

output "public_ip" {
  description = "Jenkins public IP (Elastic IP)"
  value       = aws_eip.jenkins.public_ip
}

output "public_dns" {
  description = "Jenkins public DNS"
  value       = aws_instance.jenkins.public_dns
}

output "jenkins_url" {
  description = "URL truy cập Jenkins"
  value       = "http://${aws_eip.jenkins.public_ip}:8080"
}

output "security_group_id" {
  description = "Security Group ID"
  value       = aws_security_group.jenkins.id
}

output "ssh_command" {
  description = "Lệnh SSH vào Jenkins server"
  value       = "ssh -i ~/.ssh/${var.key_name} ubuntu@${aws_eip.jenkins.public_ip}"
}
