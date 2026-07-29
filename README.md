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
      │ CI/CD Pipeline: Build → Push → ArgoCD sync
      ▼
 ┌──────────────────────────────────────────────────────────┐
 │                    EKS Cluster                            │
 │  ┌──────────┐  ┌──────────┐  ┌────────────────────────┐  │
 │  │  Vault   │  │  ArgoCD  │  │  namespace: demo-app    │  │
 │  │  (HA x3) │  │  App-of- │  │                          │  │
 │  │    ↓     │  │  Apps    │  │  ALB Ingress              │  │
 │  │   ESO    │  └──────────┘  │    ↓                      │  │
 │  │    ↓     │                │  Frontend (Rollout: B/G)   │  │
 │  │  Secret  │                │    ↓                      │  │
 │  └──────────┘                │  Backend (Rollout: Canary) │  │
 │                              │    ↓                      │  │
 │                              │  MySQL 8.0 (StatefulSet)   │  │
 │                              │  PVC 5Gi gp3               │  │
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
  1. Verify Tools
  2. Checkout Code
  3. Docker Login
  4. Lint (Backend + Frontend)
  5. Test (Backend + Frontend)
  6. Build & Push (Backend + Frontend → Docker Hub)
  7. Trivy Security Scan
  8. Update GitOps (sed tag → git push)
    │
    ▼
ArgoCD:
  Detect values.yaml change → Sync Wave 0→1→2 → App updated
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
| Secret Management | HashiCorp Vault (HA) + External Secrets Operator |
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
│   │   ├── externalsecret.yaml    # ESO sync Vault → K8s Secret
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
# Init + unseal + store MySQL credentials (1 script)
cd infra/vault
cp vault.env.example vault.env   # Sửa password
bash vault-init.sh

# ===== ArgoCD App-of-Apps =====
# Deploy dev-root → ArgoCD tự sync toàn bộ demo-app (DEV)
kubectl apply -f argocd/app-of-apps/dev-root.yaml
kubectl get pods -n demo-app -w

# ===== Dev Tools (CLI) =====
bash infra/scripts/install-tools.sh
```

### 3. Deploy to Staging & Production

```bash
# ===== STAGING =====
# Infrastructure (nếu cần cluster riêng)
cd infra/envs/stg/compute
terraform init && terraform apply -auto-approve

# Deploy app → ArgoCD auto-sync
kubectl apply -f argocd/app-of-apps/stg-root.yaml
kubectl get pods -n demo-app-stg -w

# ===== PRODUCTION =====
# Infrastructure (nếu cần cluster riêng)
cd infra/envs/prd/compute
terraform init && terraform apply -auto-approve

# Deploy app → ArgoCD auto-sync
kubectl apply -f argocd/app-of-apps/prd-root.yaml
kubectl get pods -n demo-app-prd -w

# ⚠️ Vault secrets dùng chung cho mọi environment
# ArgoCD sẽ tự deploy ExternalSecret ở namespace tương ứng
# Vault role đã whitelist: demo-app, demo-app-stg, demo-app-prd
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

| ID | Kind |
|----|------|
| `dockerhub-credentials` | Username with password |
| `github-token` | Secret text |

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
| Vault Token | `aws ssm get-parameter --name '/devops-lab/vault/root-token' --with-decryption --region us-east-1 --profile root-lab-2 --query 'Parameter.Value' --output text` |
| Jenkins | http://<JENKINS_EIP>:8080 |
| Jenkins Password | `cat /var/jenkins_home/secrets/initialAdminPassword` (SSH vào EC2) |
| Rancher | https://<RANCHER_EIP>.sslip.io |

## Security

| Measure | Detail |
|---------|--------|
| SG IP Whitelist | Jenkins + Rancher restricted to trusted IP only |
| Image Scanning | Trivy HIGH + CRITICAL in every build |
| Secret Mgmt | **HashiCorp Vault + ESO** — secrets never in Git, auto-sync to K8s |
| Encryption | Vault encrypts at rest, AWS KMS for SSM & EKS |
| GitOps Audit | All changes via Git history |

> ⚠️ **Lesson:** Jenkins port 8080 open to internet → hacked within minutes → EC2 used for DDoS. **Fix:** IP whitelist in Security Group.

## Vault Integration

```
  vault kv put (1 lần) → Vault (mã hóa) → ESO (auto sync) → K8s Secret → Pod
```

| Component | Role |
|-----------|------|
| **Vault** (3 pods, HA) | Lưu secrets mã hóa, audit log, phân quyền |
| **ESO** (1 pod) | Đọc Vault → tạo K8s Secret tự động mỗi 1h |
| **ExternalSecret** | Khai báo: "Vault path X → K8s Secret Y" |
| **SecretStore** | Khai báo: "Kết nối Vault ở đâu, auth thế nào" |

**Lợi ích:**
- Đổi password: `vault kv patch` 1 lần → ESO tự sync 15 K8s Secrets
- Audit: biết ai đọc secret lúc nào
- Không còn `kubectl create secret` thủ công

## ArgoCD Features

| Feature | Description |
|---------|-------------|
| App-of-Apps | 1 root app → auto-create all child apps |
| Sync Wave | SecretStore (Wave -2) → ExternalSecret (Wave -1) → MySQL (Wave 0) → Backend (Wave 1) → Frontend+Ingress (Wave 2) |
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
