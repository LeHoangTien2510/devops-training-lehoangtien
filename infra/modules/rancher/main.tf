# =============================================================================
# MODULE: Rancher EC2 – Quản lý Kubernetes Cluster
# =============================================================================

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

# =========================================================
# Security Group
# =========================================================
resource "aws_security_group" "rancher" {
  name        = "${var.name}-rancher-sg"
  description = "Rancher Server"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["14.232.69.20/32", "183.80.98.34/32", "118.71.65.73/32"]
    description = "SSH"
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["14.232.69.20/32", "183.80.98.34/32"]
    description = "Rancher HTTP (redirect to HTTPS)"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["14.232.69.20/32", "183.80.98.34/32", "118.71.65.73/32"]
    description = "Rancher HTTPS"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.name}-rancher-sg"
    Environment = var.environment
  }
}

# =========================================================
# IAM Role – cho Rancher quản lý EKS + Route53 (nếu cần)
# =========================================================
data "aws_iam_policy_document" "rancher_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "rancher" {
  name               = "${var.name}-rancher-role"
  assume_role_policy = data.aws_iam_policy_document.rancher_assume.json

  tags = { Environment = var.environment }
}

resource "aws_iam_role_policy" "rancher_eks" {
  name = "${var.name}-rancher-eks-policy"
  role = aws_iam_role.rancher.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["eks:DescribeCluster", "eks:ListClusters"]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_instance_profile" "rancher" {
  name = "${var.name}-rancher-profile"
  role = aws_iam_role.rancher.name
}

# =========================================================
# EC2 Instance – Rancher Server
# =========================================================
resource "aws_instance" "rancher" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = var.public_subnet_id
  vpc_security_group_ids      = [aws_security_group.rancher.id]
  iam_instance_profile        = aws_iam_instance_profile.rancher.name
  key_name                    = var.key_name
  associate_public_ip_address = true

  root_block_device {
    volume_type = "gp3"
    volume_size = var.root_volume_size
    encrypted   = true
  }

  user_data = <<-EOF
    #!/bin/bash
    set -e
    apt-get update -y && apt-get upgrade -y
    curl -fsSL https://get.docker.com | bash
    systemctl enable docker && systemctl start docker
    usermod -aG docker ubuntu
    echo "✅ Docker ready. Chờ Ansible provision Rancher."
  EOF

  tags = {
    Name        = "${var.name}-rancher"
    Environment = var.environment
    Role        = "rancher"
  }
}

# =========================================================
# Elastic IP
# =========================================================
resource "aws_eip" "rancher" {
  instance = aws_instance.rancher.id
  domain   = "vpc"

  tags = {
    Name        = "${var.name}-rancher-eip"
    Environment = var.environment
  }
}
