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
 ┌─────────────────────────────────────────────┐
 │              EKS Cluster                     │
 │  ┌─────────┐  ┌──────────────────────────┐  │
 │  │ ArgoCD  │  │  namespace: demo-app      │  │
 │  │ App-of- │  │                            │  │
 │  │ Apps    │  │  ALB Ingress                │  │
 │  └─────────┘  │    ↓                        │  │
 │               │  Frontend (Angular): 2 pods  │  │
 │               │    ↓                        │  │
 │               │  Backend (Spring): 2 pods    │  │
 │               │    ↓                        │  │
 │               │  MySQL 8.0 (StatefulSet)     │  │
 │               │  PVC 5Gi gp3                 │  │
 │               └──────────────────────────────┘  │
 │  2 node c7i-flex.large                           │
 └──────────────────────────────────────────────────┘
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
| CI | Jenkins (self-hosted EC2) |
| IaC | Terraform (S3 backend, multi-env) |
| Config Mgmt | Ansible |
| Security | Trivy, SG IP whitelist, IAM least privilege |

## Project Structure

```
.
├── charts/demo-app/           # Helm chart 3-tier app
│   ├── values.yaml            # Jenkins auto-updates tag
│   ├── templates/             # K8s manifests + hooks
│   └── manual/                # Secret templates
├── infra/
│   ├── modules/               # Terraform modules
│   │   ├── network/           # VPC + subnets
│   │   ├── compute/           # EKS + ArgoCD
│   │   ├── jenkins/           # EC2 Jenkins
│   │   └── rancher/           # EC2 Rancher
│   ├── envs/dev/              # Dev environment
│   ├── envs/stg/              # Staging environment
│   ├── ansible/               # Ansible playbooks
│   └── bootstrap-backend/     # S3 + DynamoDB
├── argocd/                    # ArgoCD App-of-Apps
│   ├── app-of-apps/dev-root.yaml
│   └── applications/dev/demo-app.yaml
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
kubectl create ns demo-app
kubectl -n demo-app create secret generic mysql-secret \
  --from-literal=mysql-root-password=STRONG_PASS \
  --from-literal=mysql-database=full-stack-ecommerce \
  --from-literal=mysql-user=ecommerceapp \
  --from-literal=mysql-password=STRONG_PASS

kubectl apply -f argocd/app-of-apps/dev-root.yaml
kubectl get pods -n demo-app -w
```

### 3. Jenkins EC2

```bash
cd infra/envs/dev/jenkins
terraform init && terraform apply -auto-approve

cd ../../../ansible
./run.sh jenkins-playbook.yml
# → http://<JENKINS_IP>:8080
```

### 4. Jenkins Credentials

| ID | Kind |
|----|------|
| `dockerhub-credentials` | Username with password |
| `github-token` | Secret text |

### 5. Test CI/CD

```bash
git add -A && git commit -m "Test" && git push origin Week-5-CICD
# Jenkins builds → pushes tag → ArgoCD auto-syncs
```

## Access

| Service | How to Access |
|---------|---------------|
| Demo App | `kubectl get ingress -n demo-app` → ALB DNS |
| ArgoCD | `kubectl port-forward -n argocd svc/argocd-server 8443:443` → https://localhost:8443 |
| ArgoCD Password | `kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d` |
| Jenkins | http://<JENKINS_EIP>:8080 |
| Jenkins Password | `cat /var/jenkins_home/secrets/initialAdminPassword` (SSH vào EC2) |
| Rancher | https://<RANCHER_EIP>.sslip.io |

## Security

| Measure | Detail |
|---------|--------|
| SG IP Whitelist | Jenkins + Rancher restricted to trusted IP only |
| Image Scanning | Trivy HIGH + CRITICAL in every build |
| Secret Mgmt | MySQL password in K8s Secret, never in Git |
| GitOps Audit | All changes via Git history |

> ⚠️ **Lesson:** Jenkins port 8080 open to internet → hacked within minutes → EC2 used for DDoS. **Fix:** IP whitelist in Security Group.

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
