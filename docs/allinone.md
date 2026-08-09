# 🚀 All-in-One CI/CD Pipeline – Hướng dẫn

## Kiến trúc

```
Developer push code → GitHub
    │
    ▼
Jenkins (EC2, --network host)
    │
    ├── vault login → Vault (EKS, Internal NLB) → đọc secrets
    ├── docker build → Docker Hub
    ├── kubectl create secret → EKS (public endpoint)
    └── kubectl argo rollouts set image → EKS
           │
           ▼
    Argo Rollouts controller → Canary (backend) / Blue-Green (frontend)
```

## Parameters

| Parameter | Default | Mô tả |
|-----------|---------|-------|
| `PROJECT_NAME` | `demo-app` | Tên project |
| `ENVIRONMENT` | `dev` / `stg` / `prd` | Môi trường deploy |
| `GIT_BRANCH` | `Week-8-CI-full` | Branch source code |
| `MODULE_DEPLOY` | `backend,frontend` | Chọn component: `backend`, `frontend`, `backend,frontend` |
| `DOCKER_BACKEND_REPO` | `lehoangtien2510/ecommerce-backend` | Docker Hub repo backend |
| `DOCKER_FRONTEND_REPO` | `lehoangtien2510/ecommerce-frontend` | Docker Hub repo frontend |
| `VAULT_ADDR` | `http://<NLB>:8200` | Vault Internal NLB URL |
| `VAULT_APP_PATH` | `secret/demo-app/mysql` | Path app secrets |
| `VAULT_COMMON_PATH` | `secret/common` | Path common secrets |
| `KUBE_NAMESPACE` | *(để trống)* | Tự tính = `PROJECT_NAME-ENVIRONMENT` |
| `KUBE_CONFIG_CRED` | `kubeconfig` | Jenkins credential ID chứa kubeconfig |

## Cách lấy VAULT_ADDR

```bash
kubectl get svc vault -n vault -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
# Output: k8s-vault-vault-xxxx.elb.us-east-1.amazonaws.com
# → VAULT_ADDR = http://k8s-vault-vault-xxxx.elb.us-east-1.amazonaws.com:8200
```

## Pipeline Stages

| # | Stage | Mô tả |
|---|-------|-------|
| 1 | Verify Tools | Kiểm tra docker, vault, kubectl, trivy |
| 2 | Checkout | Git clone source code |
| 3 | 🔐 Get Secrets | `vault login` → đọc registry, sonarqube, mysql |
| 4 | Docker Login | Login Docker Hub |
| 5 | Lint | Checkstyle (BE) + ng lint (FE) |
| 6 | Test | JUnit + jacoco (BE) + ng test (FE) |
| 7 | SonarQube | Phân tích code quality |
| 8 | Build & Push | Docker build + push Docker Hub |
| 9 | Trivy Scan | Quét lỗ hổng HIGH/CRITICAL |
| 10 | 🔧 Create Secrets | `kubectl create secret mysql-secret` |
| 11 | 🚀 Deploy | `kubectl argo rollouts set image` → Canary/B-G |

## Jenkins Credentials

| ID | Loại | Mô tả |
|----|------|-------|
| `vault-token` | Secret text | Token cho `vault login` (lấy từ `vault-init.sh`) |
| `kubeconfig` | Secret file | File `~/.kube/config` (từ `aws eks update-kubeconfig`) |

## Vault Structure

```
secret/
├── common/
│   ├── registry → dockerhub_user, dockerhub_password
│   └── tools    → sonarqube_token
└── demo-app/
    └── mysql    → root-password, database, username, password
```

## Setup lần đầu

```bash
# 1. Terraform: tạo EKS + cài các Helm chart
cd infra/envs/dev/network && terraform apply
cd infra/envs/dev/compute && terraform apply   # đã có Vault, ArgoCD, Prometheus...

# 2. Init Vault
bash infra/vault/vault-init.sh
# → Lưu vault-token cho Jenkins
# → Tạo secrets: secret/common/registry, secret/common/tools, secret/demo-app/mysql

# 3. Deploy Jenkins (Ansible)
cd infra/ansible
ansible-playbook -i inventory.ini jenkins-playbook.yml

# 4. Cấu hình Jenkins
#    - Thêm credential: vault-token (Secret text)
#    - Thêm credential: kubeconfig (Secret file, upload ~/.kube/config)
#    - Tạo Pipeline job → trỏ đến Jenkinsfile.allinone

# 5. Provision app (1 lần)
kubectl create namespace demo-app-dev
kubectl create secret generic mysql-secret -n demo-app-dev \
  --from-literal=mysql-root-password='...' --from-literal=mysql-database='...' \
  --from-literal=mysql-user='...' --from-literal=mysql-password='...'
helm install demo-app charts/demo-app -n demo-app-dev -f charts/demo-app/values.yaml

# 6. Build with Parameters trên Jenkins
```

## Progressive Delivery

| Component | Strategy | Chi tiết |
|-----------|----------|----------|
| Backend | **Canary** | 10% → pause 60s → phân tích error rate → 50% → 60s → 100% |
| Frontend | **Blue-Green** | Tạo Green stack → promote lần 1 → pause → promote lần 2 → switch traffic |

## Troubleshooting

| Lỗi | Nguyên nhân | Fix |
|-----|------------|-----|
| `source: not found` | Jenkins dùng dash shell | Đã fix: dùng `.` thay `source` |
| `dial tcp 10.0.x.x:443 i/o timeout` | EKS private endpoint bị chặn | Đã fix: `cluster_endpoint_private_access = false` |
| `executable aws not found` | Thiếu AWS CLI | Đã fix: thêm vào Dockerfile.jenkins |
| `kubectl argo: unknown command` | Thiếu plugin | Đã fix: thêm vào Dockerfile.jenkins |
| Blue-Green bị pause mãi | Cần 2 lần promote | Đã fix: pipeline promote 2 lần |
