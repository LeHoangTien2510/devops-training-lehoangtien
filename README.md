# DevOps Training — Le Hoang Tien

## 🏗️ Kiến trúc hệ thống

```
                              INTERNET
                                 │
                                 ▼
                    ┌─────────────────────────┐
                    │     AWS ALB (Ingress)    │
                    │  internet-facing, TLS    │
                    │  cert-manager (selfsigned)│
                    └─────┬──────┬──────┬──────┘
                          │      │      │
                    /     │  /api│      │ /grafana
                         ▼      ▼      ▼
              ┌──────────┐ ┌────────┐ ┌──────────┐
              │ Frontend │ │Backend │ │ Grafana  │
              │ Angular  │ │Spring  │ │(monitoring│
              │ nginx:80 │ │Boot:8080│ │   :80)   │
              │  (2 pods)│ │(2 pods)│ │          │
              └──────────┘ └───┬────┘ └──────────┘
                               │ JDBC
                               │ jdbc:mysql://mysql:3306
                               ▼
                    ┌─────────────────────┐
                    │   MySQL StatefulSet │
                    │   mysql:3306        │
                    │   1 pod + PVC 5Gi   │
                    │   gp3 (EBS CSI)     │
                    └────────┬────────────┘
                             │
                    ┌────────▼────────────┐
                    │   AWS EBS Volume    │
                    │   5Gi gp3 SSD       │
                    └─────────────────────┘

┌──────────────────────────────────────────────────────┐
│                  AWS EKS Cluster                     │
│  ┌─────────────┐  ┌──────────────┐  ┌─────────────┐ │
│  │ cert-manager│  │    ArgoCD    │  │  Prometheus  │ │
│  │ (TLS certs) │  │ (GitOps CD)  │  │  + AlertMgr  │ │
│  └─────────────┘  └──────────────┘  └─────────────┘ │
│  ┌─────────────────────────────────────────────────┐ │
│  │  EBS CSI Driver  │  AWS LB Controller          │ │
│  └─────────────────────────────────────────────────┘ │
│  2 node t3a.large (us-east-1)                       │
└──────────────────────────────────────────────────────┘
```

## 🧱 Tech Stack

| Layer | Công nghệ |
|-------|-----------|
| **Frontend** | Angular + Nginx |
| **Backend** | Spring Boot (Java 17) |
| **Database** | MySQL 8.0 (StatefulSet) |
| **Container** | Docker, Docker Hub |
| **Orchestration** | Kubernetes (AWS EKS 1.31) |
| **Ingress** | AWS ALB Ingress Controller |
| **TLS** | cert-manager + ClusterIssuer (self-signed) |
| **Storage** | EBS CSI Driver + gp3 StorageClass + PVC 5Gi |
| **Monitoring** | kube-prometheus-stack (Grafana + Prometheus + AlertManager) |
| **GitOps CD** | ArgoCD |
| **CI** | GitHub Actions (build + Trivy scan + SBOM + Cosign sign) |
| **CD** | GitHub Actions (verify signature + Helm deploy) |
| **IaC** | Terraform (S3 backend + DynamoDB lock) |
| **Secrets** | Kubernetes Secret (mysql-secret) |

## 📁 Cấu trúc dự án

```
.
├── charts/demo-app/              # Helm chart 3-tier app
│   ├── Chart.yaml
│   ├── values.example.yaml       # File mẫu (an toàn commit)
│   ├── values.yaml               # Secret thật (gitignored)
│   ├── sql/                      # Scripts init MySQL
│   └── templates/                # K8s manifests
│       ├── storageclass.yaml     # gp3 StorageClass
│       ├── secret.yaml           # MySQL credentials
│       ├── configmap.yaml        # Backend config
│       ├── mysql-statefulset.yaml
│       ├── backend.yaml
│       ├── frontend.yaml
│       ├── ingress.yaml
│       ├── servicemonitor.yaml
│       └── clusterissuer.yaml
├── infra/                        # Terraform IaC
│   ├── modules/
│   │   ├── network/              # VPC, subnets, NAT, IGW
│   │   └── compute/              # EKS, IAM, Helm releases
│   ├── envs/
│   │   ├── dev/                  # Dev environment
│   │   └── stg/                  # Staging environment
│   ├── bootstrap-backend/        # S3 + DynamoDB state
│   └── observability/            # Monitoring configs
├── src/                          # Source code
│   ├── 02-backend_spring-boot-rest-api/
│   ├── 03-frontend_angular-ecommerce/
│   └── 01-starter-files_db-scripts/
├── argocd/                       # ArgoCD config
├── .github/workflows/            # CI/CD pipelines
└── README.md
```

## 🚀 Deploy

### Yêu cầu

- AWS CLI + profile `root-lab-2`
- Terraform >= 1.5
- kubectl + Helm 3
- Docker Hub account

### 1. Terraform (IaC)

```bash
# Bootstrap (chỉ 1 lần)
cd infra/bootstrap-backend
terraform init && terraform apply -auto-approve

# Network (VPC)
cd ../envs/dev/network
cp terraform.tfvars.example terraform.tfvars
terraform init && terraform apply -auto-approve

# Compute (EKS + toàn bộ stack)
cd ../compute
cp terraform.tfvars.example terraform.tfvars
terraform init && terraform apply -auto-approve
```

### 2. Kết nối cluster

```bash
aws eks update-kubeconfig --region us-east-1 --name eks-devops-lab --profile root-lab-2
kubectl get pods -n demo-app
```

### 3. Truy cập

| Dịch vụ | URL |
|---------|-----|
| App | `http://<ALB-DNS>/` |
| Backend API | `http://<ALB-DNS>/api/products` |
| Grafana | `http://<ALB-DNS>/grafana` (admin / admin123) |
| Prometheus | `kubectl port-forward -n demo-app svc/kube-prometheus-stack-prometheus 9090:9090` |
| ArgoCD | `kubectl port-forward -n argocd svc/argocd-server 8080:443` |

```bash
# Lấy ALB DNS
kubectl get ingress -n demo-app ecommerce-ingress
```

## 🔐 Secrets

- `charts/demo-app/values.yaml` — gitignored, chứa MySQL passwords
- `*.tfvars` — gitignored, chứa AWS config
- `mysql-secret` (K8s Secret) — tự động tạo bởi Helm chart
- Backend đọc password từ `${MYSQL_PASSWORD}` env → Secret

## 📊 Monitoring

- **Grafana**: dashboards preloaded (Node Exporter, K8s Cluster, Nginx)
- **Prometheus**: scrape metrics mỗi 30s
- **AlertManager**: 
  - `PodRestartHigh`: pod restart > 3 lần/10 phút → warning

## 🔄 CI/CD

```
Git Push (main) → GitHub Actions:
  1. Build Backend + Frontend Docker images
  2. Trivy scan (CRITICAL, HIGH)
  3. SBOM (Syft CycloneDX)
  4. Push Docker Hub
  5. Cosign keyless sign (OIDC)
  6. Verify signatures
  7. Helm deploy to EKS
```

## 🗂️ Runbook

Xem [RUNBOOK.md](RUNBOOK.md) để biết cách xử lý khi production gặp sự cố.
