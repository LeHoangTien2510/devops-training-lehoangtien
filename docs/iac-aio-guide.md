# 🏗️ IaC All-in-One — Hướng dẫn đầy đủ

> **Ngày tạo**: 2026-08-10
> **Tác giả**: Lê Hoàng Tiến
> **Mentor yêu cầu**: IaC All-in-One với UI + Vault + Terraform

---

## Kiến trúc

```
┌──────────────────────────────────────────────────────────┐
│                     3 LỚP KIẾN TRÚC                       │
│                                                          │
│  Lớp UI              Lớp Backend          Lớp Data       │
│  ─────────          ────────────          ────────       │
│                                                          │
│  HTML UI ──────┐                                        │
│  (port 7070)    │     ┌──────────────┐    ┌──────────┐  │
│                 ├────▶│  server.py   │───▶│  Vault   │  │
│  Backstage ────┘     │  (port 7070)  │    │ (port    │  │
│  (port 3001)          │              │    │  8200)   │  │
│                       │ - Đọc Vault  │    └──────────┘  │
│                       │ - Gen tfvars │                   │
│                       │ - Terraform  │    ┌──────────┐  │
│                       └──────────────┘───▶│   AWS    │  │
│                                           └──────────┘  │
└──────────────────────────────────────────────────────────┘
```

---

## 0. Prerequisites

Cần chạy đồng thời 3 terminal:

```bash
# Terminal 1: Port-forward Vault (giữ nguyên, không tắt)
kubectl port-forward -n vault svc/vault 8200:8200

# Terminal 2: Python backend server
cd ~/work/devops-training-lehoangtien
VAULT_TOKEN=$(python3 -c "import json; print(json.load(open('infra/vault/vault-credentials.json'))['root_token'])") \
  python3 platform/iac-backend/server.py

# Terminal 3: Backstage (hoặc mở HTML UI)
cd ~/work/devops-training-lehoangtien/backstage-portal
yarn start
```

---

## 1. Khởi tạo Vault + Sync biến Infrastructure

### 1.1. Init & Unseal Vault

```bash
cd ~/work/devops-training-lehoangtien

# Chạy 1 lần duy nhất (đã làm ngày 2026-08-10)
bash infra/vault/vault-init.sh
```

Script này sẽ:
- Init Vault (5 key shares, 3 threshold)
- Unseal 3 pods
- Enable KV v2, Kubernetes Auth, AppRole
- Tạo root token → lưu vào `infra/vault/vault-credentials.json`

### 1.2. Lấy Vault Token

```bash
# Root token nằm trong file:
python3 -c "import json; print(json.load(open('infra/vault/vault-credentials.json'))['root_token'])"

# Output: hvs.YOUR_ROOT_TOKEN_HERE (ví dụ – token thật nằm trong vault-credentials.json)
```

> ⚠️ Token này dùng để gọi Vault API từ Python backend. Mỗi lần Vault recreate phải chạy lại vault-init.sh.

### 1.3. Sync biến Infrastructure lên Vault

```bash
# Sync các biến từ terraform.tfvars hiện tại → Vault
python3 infra/vault/sync_infra_vars.py
```

Cấu trúc Vault sau khi sync:

```
secret/
├── dev/infrastructure/
│   ├── aws_profile = "root-lab-2"
│   ├── cluster_name = "eks-devops-lab"
│   ├── vpc_cidr = "10.0.0.0/16"
│   ├── node_desired_size = 2
│   └── ...
│
├── stg/infrastructure/
│   ├── cluster_name = "eks-devops-lab-stg"
│   ├── vpc_cidr = "10.1.0.0/16"
│   ├── node_desired_size = 3
│   └── ...
│
└── prd/infrastructure/
    ├── cluster_name = "eks-devops-lab-prd"
    ├── vpc_cidr = "10.2.0.0/16"
    ├── node_desired_size = 5
    └── ...
```

**Kiểm tra Vault data**:
```bash
# Mở browser:
http://localhost:7070/api/iac-vault/dev/infrastructure
http://localhost:7070/api/iac-vault/stg/infrastructure
http://localhost:7070/api/iac-vault/prd/infrastructure
```

---

## 2. Chạy Python Backend (server.py)

```bash
cd ~/work/devops-training-lehoangtien

# Lấy Vault token + chạy server
VAULT_TOKEN=$(python3 -c "import json; print(json.load(open('infra/vault/vault-credentials.json'))['root_token'])") \
  python3 platform/iac-backend/server.py
```

API endpoints:
| Method | Path | Mô tả |
|--------|------|-------|
| GET | `/api/health` | Health check |
| GET | `/api/iac-vault/{env}/infrastructure` | Đọc config từ Vault |
| POST | `/api/iac-generate-tfvars` | Sinh file terraform.tfvars |
| GET | `/api/iac-terraform-stream?env=&layers=&action=` | SSE streaming terraform |

---

## 3. HTML UI (Demo nhanh)

### 3.1. Mở UI

```bash
# Mở browser, vào:
file:///home/tien/work/devops-training-lehoangtien/platform/iac-ui/index.html
```

### 3.2. Sử dụng

1. Chọn Environment: DEV / STG / PRD
2. Chọn Components: Network, Compute, Jenkins, Rancher
3. Xem Vault config tự động load
4. Bấm **PLAN** (xem trước) hoặc **APPLY** (triển khai thật)
5. Xem log terraform realtime (từng dòng)

### 3.3. Flow xử lý

```
UI bấm APPLY → EventSource kết nối SSE → server.py:
  1. Đọc Vault: secret/{env}/infrastructure
  2. Ghi file: infra/envs/{env}/{layer}/terraform.tfvars
  3. cd infra/envs/{env}/{layer}
  4. terraform init
  5. terraform plan -out=tfplan
  6. terraform apply -auto-approve tfplan
  7. Auto-clean terraform.tfvars
  8. (Nếu layer=jenkins/rancher) ansible-playbook
```

---

## 4. Backstage (Production UI)

### 4.1. Setup lần đầu

```bash
# Đã tạo ngày 2026-08-10, chỉ cần làm 1 lần
cd ~/work/devops-training-lehoangtien

# Cài Node 22 (nếu chưa có)
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
source ~/.bashrc
nvm install 22
nvm use 22

# Cài yarn
sudo corepack enable

# Tạo Backstage app
npx @backstage/create-app@latest
# → Nhập tên: backstage-portal
```

### 4.2. Thêm IaC AIO template

Template đã được copy vào `backstage-portal/templates/template.yaml`.
Đường dẫn đã đăng ký trong `app-config.yaml`:

```yaml
catalog:
  locations:
    - target: ../../templates/template.yaml
      type: file
      rules:
        - allow: [Template]
```

### 4.3. Custom backend action

Đã tạo 3 file trong Backstage backend:
- `packages/backend/src/plugins/iacAioAction.ts` — Custom action `iac:terraform`
- `packages/backend/src/plugins/scaffolderModuleIacAio.ts` — Module đăng ký
- `packages/backend/src/index.ts` — Import module

Action `iac:terraform` gọi Python API → đọc Vault → chạy Terraform.

### 4.4. Proxy đến Python backend

```yaml
# Trong app-config.yaml:
proxy:
  endpoints:
    /iac-api/:
      target: http://localhost:7070
```

### 4.5. Chạy Backstage

```bash
cd ~/work/devops-training-lehoangtien/backstage-portal

# Build TypeScript (nếu có thay đổi code)
yarn tsc

# Start
yarn start
# → http://localhost:3001
```

### 4.6. Sử dụng

1. Vào Create → **🏗️ IaC All-in-One**
2. Step 1: Nhập Project Name, chọn Environment
3. Step 2: Chọn Components (network, compute…), Action (plan/apply)
4. Step 3: Mở tab mới vào link Vault để kiểm tra config
5. Bấm **REVIEW** → **CREATE**
6. Backstage gọi Python backend → đọc Vault → terraform apply

---

## 5. Troubleshooting

| Lỗi | Nguyên nhân | Fix |
|-----|------------|-----|
| `ERR_IPC_CHANNEL_CLOSED` | node_modules corrupt | `rm -rf node_modules && yarn install` |
| `EADDRINUSE :3001` | Backstage cũ chưa tắt | `fuser -k 3001/tcp; fuser -k 7007/tcp` |
| Vault `permission denied` | Chưa port-forward | `kubectl port-forward -n vault svc/vault 8200:8200` |
| Template không hiện | app-config.yaml sai path | Path phải là `../../templates/template.yaml` |
| Terraform không chạy | Chưa có AWS credentials | Kiểm tra `~/.aws/credentials` có profile `root-lab-2` |

---

## 6. Destroy

```bash
# Phải destroy theo thứ tự ngược: jenkins → compute → network
cd infra/envs/dev/jenkins && terraform destroy -auto-approve
cd infra/envs/dev/compute && terraform destroy -auto-approve
cd infra/envs/dev/network && terraform destroy -auto-approve

# Xóa file state cũ nếu cần
# (state nằm trong S3: terraform-state-devops-lab-tien-v3)
```

---

## 7. Các file quan trọng

| File | Vai trò |
|------|--------|
| `infra/vault/vault-credentials.json` | Root token Vault |
| `infra/vault/sync_infra_vars.py` | Sync biến infra lên Vault |
| `platform/iac-backend/server.py` | Backend API: Vault + Terraform |
| `platform/iac-ui/index.html` | HTML UI demo |
| `platform/templates/iac-allinone/template.yaml` | Backstage template |
| `Jenkinsfile.iac-aio` | Jenkins IaC AIO pipeline |
| `Jenkinsfile.allinone` | Jenkins CI/CD AIO pipeline |
