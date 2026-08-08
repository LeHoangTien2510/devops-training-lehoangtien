# DevOps Training — Le Hoang Tien

> Full-stack DevOps project: EKS + CI/CD (Jenkins) + GitOps (ArgoCD)

---

## Architecture

```
                          AWS Cloud (us-east-1)
 ┌──────────┐  ┌──────────┐
 │ Jenkins  │  │ Rancher  │  << SG: IP whitelist only
 │ EC2 :8080│  │ EC2 :443 │
 └────┬─────┘  └──────────┘
      │ CI/CD Pipeline:
      │   1. Auth Vault (AppRole)
      │   2. Read MySQL secrets
      │   3. kubectl create secret
      │   4. Build → Push → ArgoCD sync
      │
      │  ┌─── Internal NLB ───┐
      ▼  ▼                    ▼
 ┌──────────────────────────────────────────────────────────┐
 │                    EKS Cluster                            │
 │  ┌──────────┐  ┌──────────┐  ┌────────────────────────┐  │
 │  │  Vault   │  │  ArgoCD  │  │  namespace: demo-app    │  │
 │  │  (HA x3) │  │  App-of- │  │                          │  │
 │  │  AppRole │  │  Apps    │  │  ALB Ingress              │  │
 │  │  Auth ✅ │  └──────────┘  │    ↓                      │  │
 │  │          │                │  Frontend (Rollout: B/G)   │  │
 │  │  Secrets │                │    ↓                      │  │
 │  │  KV v2   │                │  Backend (Rollout: Canary) │  │
 │  └──────────┘                │    ↓                      │  │
 │                              │  MySQL 8.0 (StatefulSet)   │  │
 │                              │  PVC 5Gi gp3               │  │
 │                              │  🔐 Secret: mysql-secret   │  │
 │                              │     (created by Jenkins)   │  │
 │                              └──────────────────────────┘  │
 │  2 node c7i-flex.large                                     │
 └──────────────────────────────────────────────────────────┘
```

## CI/CD Pipeline

```
Developer push code → GitHub (Week-5-CICD)
    │
    ▼
Jenkins Pipeline:
  1. Verify Tools (docker, vault, kubectl, trivy, ...)
  2. Checkout Code
  3. Docker Login
  4. Lint (Backend + Frontend)
  5. Test (Backend + Frontend)
  6. Build & Push (Backend + Frontend → Docker Hub)
  7. Trivy Security Scan
  8. 🔐 Fetch Secrets from Vault (AppRole Auth → Read MySQL)
  9. 🔧 Create K8s Secret (kubectl create secret → mysql-secret)
 10. Update GitOps (sed tag → git push)
    │
    ▼
ArgoCD:
  Detect values.yaml change → Sync Wave 0→1→2 → App updated
  MySQL + Backend reads mysql-secret (created by Jenkins)
```

## Tech Stack

| Layer | Technology |
|-------|------------|
| Frontend | Angular + Nginx |
| Backend | Spring Boot |
| Database | MySQL 8.0 (StatefulSet + PVC) |
| Container | Docker, Docker Hub |
| Orchestration | AWS EKS 1.31 |
| Ingress | AWS ALB Ingress Controller |
| Storage | EBS CSI Driver + gp3 |
| GitOps CD | ArgoCD (App-of-Apps, Sync Wave, Hooks) |
| Progressive Delivery | Argo Rollouts (Blue-Green + Canary) |
| Secret Management | HashiCorp Vault (HA) – Jenkins AppRole Auth → kubectl create secret |
| CI | Jenkins (self-hosted EC2) |
| IaC | Terraform (S3 backend, multi-env) |
| Config Mgmt | Ansible |
| Security | Trivy, SG IP whitelist, IAM least privilege |

## Project Structure

```
.
├── charts/demo-app/           # Helm chart 3-tier app
│   ├── values.yaml            # Jenkins auto-updates tag
│   ├── values-stg.yaml        # Staging values
│   ├── values-prd.yaml        # Production values
│   ├── templates/             # K8s manifests + hooks + rollouts
│   │   ├── rollout-backend.yaml   # Canary deployment
│   │   ├── rollout-frontend.yaml  # Blue-Green deployment
│   │   ├── externalsecret.yaml    # (DEPRECATED) ESO – không dùng nữa
│   │   └── hooks.yaml             # PreSync/PostSync/SyncFail
│   └── manual/                # Secret templates (fallback)
├── infra/
│   ├── modules/               # Terraform modules
│   │   ├── network/           # VPC + subnets
│   │   ├── compute/           # EKS + ArgoCD + Vault + ESO + Argo Rollouts
│   │   ├── jenkins/           # EC2 Jenkins
│   │   └── rancher/           # EC2 Rancher
│   ├── envs/dev/              # Dev environment
│   ├── envs/stg/              # Staging environment
│   ├── ansible/               # Ansible playbooks
│   ├── vault/                 # Vault setup scripts
│   │   ├── vault-init.sh      # Init + unseal + store secrets (1-click)
│   │   ├── vault-values.yaml  # Helm values for Vault HA
│   │   ├── vault.env          # MySQL credentials (gitignored)
│   │   └── vault.env.example  # Template for vault.env
│   ├── scripts/               # Dev tools installer
│   │   └── install-tools.sh   # kubectl-argo-rollouts, argocd CLI, helm
│   └── bootstrap-backend/     # S3 + DynamoDB
├── argocd/                    # ArgoCD App-of-Apps
│   ├── app-of-apps/           # Root apps (dev/stg/prd)
│   └── applications/          # Child app manifests
├── src/                       # Source code
├── Jenkinsfile                # CI/CD pipeline
└── Dockerfile.jenkins         # Custom Jenkins image
```

## How to Deploy

### Prerequisites

- AWS CLI + profile `root-lab-2`
- Terraform >= 1.5, kubectl + Helm 3, Ansible
- Docker Hub account
- GitHub Token (scope: `repo`)
- AWS Key Pair

### 1. Infrastructure

```bash
# Bootstrap (S3 + DynamoDB)
cd infra/bootstrap-backend
terraform init && terraform apply -auto-approve

# Network (VPC)
cd ../envs/dev/network
terraform init && terraform apply -auto-approve

# Compute (EKS + ArgoCD) — ~15-20 min
cd ../compute
terraform init && terraform apply -auto-approve

aws eks update-kubeconfig --region us-east-1 --name eks-devops-lab --profile root-lab-2
kubectl get nodes
```

### 2. Kubernetes Setup

```bash
# ===== Vault (Secret Management) =====
# Bước 1: Init + Unseal + Cấu hình Auth (chạy script)
cd infra/vault
bash vault-init.sh
# ↑ Script sẽ:
#   1. Init Vault (5 key shares, 3 threshold)
#   2. Unseal 3 pods + Join Raft cluster
#   3. Enable KV v2 secrets engine
#   4. Enable Kubernetes Auth (fallback)
#   5. Enable AppRole Auth → hiển thị Role ID + Secret ID cho Jenkins
#   6. Hiển thị Vault Internal NLB DNS
#
# ⚠️ LƯU Role ID & Secret ID! Sẽ cần cho Jenkins credentials.
#
# Bước 2: TẠO MYSQL SECRET BẰNG TAY (Vault UI hoặc CLI)
#   → Mở Vault UI:
kubectl port-forward -n vault svc/vault 8200:8200
#   → http://localhost:8200 → Login Root Token
#   → Vào secret/ → Create secret → Path: demo-app/mysql
#   → Thêm 4 keys:
#       root-password = <password thật>
#       database      = full-stack-ecommerce
#       username      = ecommerceapp
#       password      = <password thật>
#
#   HOẶC dùng vault CLI (gõ trực tiếp, KHÔNG lưu vào file):
#   vault kv put secret/demo-app/mysql \
#     root-password='<password>' database='full-stack-ecommerce' \
#     username='ecommerceapp' password='<password>'
#
# ⚠️ KHÔNG dùng file .env để tránh push nhầm plaintext password lên Git!
# ⚠️ vault.env.example chỉ là template tham khảo, không dùng trong automation.

# Lấy Vault NLB DNS
kubectl get svc vault -n vault
# → Copy NLB DNS, cập nhật vào Jenkinsfile: VAULT_ADDR

# ===== ArgoCD App-of-Apps =====
kubectl apply -f argocd/app-of-apps/dev-root.yaml
kubectl get pods -n demo-app -w

# ===== Dev Tools (CLI) =====
bash infra/scripts/install-tools.sh
```

### 3. Deploy to Staging & Production

```bash
# ===== STAGING =====
cd infra/envs/stg/compute
terraform init && terraform apply -auto-approve
kubectl apply -f argocd/app-of-apps/stg-root.yaml
kubectl get pods -n demo-app-stg -w

# ===== PRODUCTION =====
cd infra/envs/prd/compute
terraform init && terraform apply -auto-approve
kubectl apply -f argocd/app-of-apps/prd-root.yaml
kubectl get pods -n demo-app-prd -w
```

### 4. Jenkins EC2

```bash
cd infra/envs/dev/jenkins
terraform init && terraform apply -auto-approve

cd ../../../ansible
./run.sh jenkins-playbook.yml
# → http://<JENKINS_IP>:8080
```

### 5. Jenkins Credentials

| ID | Kind | Description |
|----|------|-------------|
| `dockerhub-credentials` | Username with password | Docker Hub login |
| `github-token` | Secret text | GitHub PAT for git push |
| `sonarqube-token` | Secret text | SonarQube analysis token |
| `vault-role-id` | Secret text | 🔐 Vault AppRole Role ID (từ vault-init.sh output) |
| `vault-secret-id` | Secret text | 🔐 Vault AppRole Secret ID (từ vault-init.sh output) |

### 6. Test CI/CD

```bash
git add -A && git commit -m "Test" && git push origin Week-5-CICD
# Jenkins builds → pushes tag → ArgoCD auto-syncs
```

## Access

| Service | How to Access |
|---------|---------------|
| Demo App | `kubectl get ingress -n demo-app` → ALB DNS |
| ArgoCD | `kubectl port-forward -n argocd svc/argocd-server 8443:443` → https://localhost:8443 |
| ArgoCD Password | `kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' \| base64 -d` |
| Argo Rollouts Dashboard | `kubectl argo rollouts dashboard` → http://localhost:3100 |
| Vault UI | `kubectl port-forward -n vault svc/vault 8200:8200` → http://localhost:8200 |
| Vault NLB | `kubectl get svc vault -n vault` → copy NLB DNS (Jenkins dùng) |
| Jenkins | http://<JENKINS_EIP>:8080 |
| Jenkins Password | `cat /var/jenkins_home/secrets/initialAdminPassword` (SSH vào EC2) |
| Rancher | https://<RANCHER_EIP>.sslip.io |

## Security

| Measure | Detail |
|---------|--------|
| SG IP Whitelist | Jenkins + Rancher restricted to trusted IP only |
| Image Scanning | Trivy HIGH + CRITICAL in every build |
| Secret Mgmt | **HashiCorp Vault → Jenkins AppRole → kubectl create secret** — secrets never in Git |
| Encryption | Vault encrypts at rest, AWS KMS for SSM & EKS |
| GitOps Audit | All changes via Git history |

> ⚠️ **Lesson:** Jenkins port 8080 open to internet → hacked within minutes → EC2 used for DDoS. **Fix:** IP whitelist in Security Group.

## Secret Management (Vault → Jenkins → K8s)

```
┌─────────────────────────────────────────────────────────────┐
│  SECRET FLOW (KHÔNG dùng ESO)                                │
│                                                              │
│  vault-init.sh (1 lần)                                       │
│    │                                                         │
│    ├─→ Vault: secret/demo-app/mysql                         │
│    │     ├─ root-password                                   │
│    │     ├─ database                                        │
│    │     ├─ username                                        │
│    │     └─ password                                        │
│    │                                                         │
│    └─→ Vault: AppRole "jenkins"                             │
│          ├─ role-id    → Jenkins credential vault-role-id   │
│          └─ secret-id  → Jenkins credential vault-secret-id │
│                                                              │
│  Jenkins Pipeline (mỗi lần build)                            │
│    │                                                         │
│    ├─ 1. vault write auth/approle/login (AppRole)           │
│    ├─ 2. vault kv get secret/demo-app/mysql                 │
│    └─ 3. kubectl create secret generic mysql-secret         │
│                                                              │
│  K8s Pods:                                                   │
│    MySQL StatefulSet  ──── mysql-secret ──── env: MYSQL_*   │
│    Backend Rollout    ──── mysql-secret ──── env: MYSQL_*   │
└─────────────────────────────────────────────────────────────┘
```

| Component | Role |
|-----------|------|
| **Vault** (3 pods, HA) | Lưu secrets mã hóa, AppRole auth cho Jenkins |
| **Internal NLB** | Cho phép Jenkins EC2 (cùng VPC) gọi Vault qua private IP |
| **AppRole** | Machine-to-machine auth: Jenkins dùng role-id + secret-id |
| **Jenkins** | Auth Vault → đọc secret → tạo K8s Secret qua kubectl |
| **mysql-secret** | K8s Secret được Jenkins tạo/quản lý (không qua ESO) |

## ArgoCD Features

| Feature | Description |
|---------|-------------|
| App-of-Apps | 1 root app → auto-create all child apps |
| Sync Wave | MySQL (Wave 0) → Backend (Wave 1) → Frontend+Ingress (Wave 2) |
| PreSync Hook | Backup MySQL before deploy |
| PostSync Hook | Health check after deploy |
| SyncFail Hook | Alert on failure |
| Prune | Git-deleted → auto-deleted on cluster |
| Self-Heal | Manual changes → auto-reverted |

## Argo Rollouts

| Feature | Description |
|---------|-------------|
| **Blue-Green** (Frontend) | Active + Preview services, manual promote |
| **Canary** (Backend) | 10% → pause 60s → 50% → pause 60s → 100% |
| Dashboard | `kubectl argo rollouts dashboard` → http://localhost:3100 |
| CLI | `kubectl argo rollouts promote/get/retry` |
