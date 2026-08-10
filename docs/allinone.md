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

## Jenkins Credentials (cần tạo thủ công)

Vào **Manage Jenkins → Credentials → System → Global → Add Credentials**

### 1. `vault-token` (Secret text)

Token để `vault login` vào Vault qua CLI.

**Cách lấy:**
```bash
# Token được in ra khi chạy vault-init.sh
bash infra/vault/vault-init.sh
# → 🔑 JENKINS DEDICATED TOKEN: hvs.CAES...

# HOẶC tạo token mới:
ROOT_TOKEN=$(python3 -c "import json; print(json.load(open('infra/vault/vault-credentials.json'))['root_token'])")
kubectl exec -n vault vault-0 -- sh -c "VAULT_TOKEN=$ROOT_TOKEN vault token create -policy=jenkins-pipeline -ttl=720h -display-name=jenkins-allinone -format=json" | python3 -c "import json,sys; print(json.load(sys.stdin)['auth']['client_token'])"
```

| Field | Value |
|-------|-------|
| Kind | **Secret text** |
| ID | `vault-token` |
| Secret | `<token từ lệnh trên>` |

### 2. `kubeconfig` (Secret file)

File kubeconfig để `kubectl` kết nối EKS cluster.

**Cách lấy:**
```bash
# 1. Update kubeconfig local
aws eks update-kubeconfig --region us-east-1 --name eks-devops-lab --profile root-lab-2

# 2. Lấy nội dung file
cat ~/.kube/config

# 3. Copy toàn bộ → tạo file config (không đuôi) trên Windows → upload
```

| Field | Value |
|-------|-------|
| Kind | **Secret file** |
| ID | `kubeconfig` |
| File | File `config` (không đuôi, nội dung từ `~/.kube/config`) |

> ⚠️ Mỗi lần EKS cluster recreate, phải update lại credential này.

---

## Vault Secrets (cần tạo thủ công)

Vào Vault UI: `kubectl port-forward -n vault svc/vault 8200:8200` → `http://localhost:8200` → Login root token.

### 1. `secret/common/registry` — Docker Hub credentials

| Key | Value |
|-----|-------|
| `dockerhub_user` | `lehoangtien2510` |
| `dockerhub_password` | Docker Hub Access Token |

> Vào [hub.docker.com](https://hub.docker.com) → Account Settings → Security → New Access Token → copy token.

### 2. `secret/common/tools` — SonarQube token

| Key | Value |
|-----|-------|
| `sonarqube_token` | SonarQube token |

> Vào `http://<JENKINS_IP>:9000` → Administration → Security → Users → admin → Tokens → Generate Token → copy.

### 3. `secret/demo-app/mysql` — MySQL credentials

| Key | Value |
|-----|-------|
| `root-password` | `<password>` |
| `database` | `full-stack-ecommerce` |
| `username` | `ecommerceapp` |
| `password` | `<password>` |

> Tự đặt password. Phải khớp với `kubectl create secret` ở bước provision app.

---

## Vault Structure (tổng quan)

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

## Destroy (đúng cách – tránh orphan Load Balancer)

> ⚠️ **Phải xóa Helm releases TRƯỚC khi terraform destroy**, nếu không LoadBalancer sẽ bị orphan và không tự xóa được.

```bash
# 1. Xóa app (nếu đã cài thủ công)
helm uninstall demo-app -n demo-app-dev 2>/dev/null

# 2. Xóa TẤT CẢ Helm releases (xóa LoadBalancers trước)
helm uninstall vault -n vault 2>/dev/null
helm uninstall ingress-nginx -n ingress-nginx 2>/dev/null
helm uninstall kube-prometheus-stack -n demo-app 2>/dev/null
helm uninstall argocd -n argocd 2>/dev/null
helm uninstall argo-rollouts -n argo-rollouts 2>/dev/null
helm uninstall cert-manager -n cert-manager 2>/dev/null

# 3. Verify không còn LoadBalancer nào
kubectl get svc --all-namespaces | grep LoadBalancer
# → (phải trống)

# 4. Terraform destroy
cd infra/envs/dev/compute && terraform destroy -auto-approve -var="aws_profile=root-lab-2" -var="aws_region=us-east-1"
cd infra/envs/dev/network && terraform destroy -auto-approve -var="aws_profile=root-lab-2" -var="aws_region=us-east-1"

# 5. Verify trên AWS Console: EC2 → Load Balancers → (phải trống)
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
