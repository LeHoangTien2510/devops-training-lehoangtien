# =============================================================================
# MODULE: Jenkins EC2 – máy chủ CI/CD
# =============================================================================

# =========================================================
# Lấy AMI mới nhất của Ubuntu 22.04 LTS
# =========================================================
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

# =========================================================
# Security Group – Jenkins
# =========================================================
resource "aws_security_group" "jenkins" {
  name        = "${var.name}-jenkins-sg"
  description = "Jenkins CI/CD server"
  vpc_id      = var.vpc_id

  # SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["14.232.69.20/32"]
    description = "SSH"
  }

  # Jenkins Web UI
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["14.232.69.20/32"]
    description = "Jenkins Web UI"
  }

  # SonarQube Web UI
  ingress {
    from_port   = 9000
    to_port     = 9000
    protocol    = "tcp"
    cidr_blocks = ["14.232.69.20/32"]
    description = "SonarQube Web UI"
  }

  # JNLP (Jenkins agent – nếu cần sau này)
  ingress {
    from_port   = 50000
    to_port     = 50000
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]
    description = "Jenkins JNLP agents"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.name}-jenkins-sg"
    Environment = var.environment
  }
}

# =========================================================
# IAM Role – Jenkins EC2 (quyền tối thiểu)
# =========================================================
data "aws_iam_policy_document" "jenkins_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "jenkins" {
  name               = "${var.name}-jenkins-role"
  assume_role_policy = data.aws_iam_policy_document.jenkins_assume.json

  tags = {
    Environment = var.environment
  }
}

# Policy: cho phép Jenkins push/pull ECR (nếu dùng ECR thay Docker Hub)
resource "aws_iam_role_policy" "jenkins_ecr" {
  name = "${var.name}-jenkins-ecr-policy"
  role = aws_iam_role.jenkins.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:GetRepositoryPolicy",
          "ecr:DescribeRepositories",
          "ecr:ListImages",
          "ecr:DescribeImages",
          "ecr:BatchGetImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:PutImage"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:Describe*",
          "eks:DescribeCluster",
          "eks:ListClusters"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_instance_profile" "jenkins" {
  name = "${var.name}-jenkins-profile"
  role = aws_iam_role.jenkins.name
}

# =========================================================
# EC2 Instance – Jenkins Server
# =========================================================
resource "aws_instance" "jenkins" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = var.public_subnet_id
  vpc_security_group_ids      = [aws_security_group.jenkins.id]
  iam_instance_profile        = aws_iam_instance_profile.jenkins.name
  key_name                    = var.key_name
  associate_public_ip_address = true

  root_block_device {
    volume_type = "gp3"
    volume_size = var.root_volume_size
    encrypted   = true
  }

  user_data = <<-EOF
    #!/bin/bash
    # ============================================================
    # User Data – Cài đặt cơ bản: Docker + Docker Compose
    # Các bước còn lại do Ansible đảm nhiệm
    # ============================================================
    set -e

    # Update system
    apt-get update -y
    apt-get upgrade -y

    # Cài Docker
    curl -fsSL https://get.docker.com | bash
    systemctl enable docker
    systemctl start docker

    # Cài Docker Compose
    curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" \
      -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose

    # Thêm ubuntu user vào docker group
    usermod -aG docker ubuntu

    echo "✅ Docker + Docker Compose đã sẵn sàng. Chờ Ansible provision tiếp."
  EOF

  tags = {
    Name        = "${var.name}-jenkins"
    Environment = var.environment
    Role        = "jenkins"
  }
}

# =========================================================
# Elastic IP – IP tĩnh cho Jenkins
# =========================================================
resource "aws_eip" "jenkins" {
  instance = aws_instance.jenkins.id
  domain   = "vpc"

  tags = {
    Name        = "${var.name}-jenkins-eip"
    Environment = var.environment
  }
}
