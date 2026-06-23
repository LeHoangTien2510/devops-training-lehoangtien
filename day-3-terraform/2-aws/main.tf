# 1. Tạo VPC
resource "aws_vpc" "main" {
  cidr_block           = "10.20.0.0/16"
  enable_dns_hostnames = true
  tags = { Name = "mini-lab-vpc" }
}

# Lấy danh sách các AZ khả dụng trong Region tự động
data "aws_availability_zones" "available" {
  state = "available"
}

# 2. Tạo 2 Public Subnet ở 2 AZ khác nhau
resource "aws_subnet" "public_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.20.1.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]
  tags = { Name = "public-subnet-1" }
}

resource "aws_subnet" "public_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.20.2.0/24"
  availability_zone = data.aws_availability_zones.available.names[1]
  tags = { Name = "public-subnet-2" }
}

# 3. Tạo Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "main-igw" }
}

# 4. Tạo Route Table và tuyến đường ra Internet
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = { Name = "public-route-table" }
}

# Liên kết Route Table vào 2 Subnet để chuyển thành Public Subnet
resource "aws_route_table_association" "pub_1" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "pub_2" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public.id
}

# 5. Tạo Security Group (Cho phép SSH từ My IP & HTTP từ Anywhere)
resource "aws_security_group" "web_sg" {
  name        = "allow_web_and_ssh"
  description = "Allow SSH and HTTP traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH from my IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "web-node-sg" }
}

# Lấy AMI ID mới nhất của Amazon Linux 2023
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-202*-x86_64"]
  }
}

# 6. Khởi tạo thực thể EC2 t3.micro trong Public Subnet 1
resource "aws_instance" "web" {
  ami                         = data.aws_ami.amazon_linux_2023.id
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.public_1.id
  vpc_security_group_ids      = [aws_security_group.web_sg.id]
  associate_public_ip_address = true

  # Khai báo đoạn script cài đặt Nginx hiển thị chuỗi text yêu cầu
  user_data = <<-EOF
              #!/bin/bash
              dnf update -y
              dnf install nginx -y
              systemctl start nginx
              systemctl enable nginx
              echo "hello from $(hostname -f)" > /usr/share/nginx/html/index.html
              EOF

  tags = { Name = "web-server-ec2" }
}

# 7. Cấp phát Elastic IP (EIP) dính vào EC2 Instance
resource "aws_eip" "web_eip" {
  instance = aws_instance.web.id
  domain   = "vpc"
  tags     = { Name = "web-elastic-ip" }
}

terraform {
  backend "s3" {
    bucket         = "tfstate-tien-1234"          # Tên bucket bạn vừa tạo ở Bước 1
    key            = "phase1/week2/day3.tfstate"   # Đường dẫn file state bên trong bucket
    region         = "us-east-1"        
    dynamodb_table = "tfstate-lock"                # Tên DynamoDB table dùng để lock state
    encrypt        = true                          # Bật mã hóa để bảo mật dữ liệu
  }
}
