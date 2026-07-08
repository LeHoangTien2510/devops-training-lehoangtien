aws_region         = "us-east-1"
environment        = "dev"
cluster_name       = "eks-devops-lab"
vpc_cidr           = "10.0.0.0/16"
public_subnets     = ["10.0.101.0/24", "10.0.102.0/24"]
private_subnets    = ["10.0.1.0/24", "10.0.2.0/24"]
node_instance_type = "t3a.large" # Máy 8GB RAM bao mượt cho các tool sau này
