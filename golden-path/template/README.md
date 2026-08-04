# =============================================================================
# Golden Path – README cho Developer
# Dev đọc file này → biết cách tạo service mới trong 5 phút
# =============================================================================

# 🚀 Golden Path: Tạo Microservice Mới

Dành cho developer muốn tạo service mới mà **không cần biết DevOps**.

## Cách dùng (3 bước)

### 1. Tạo repo từ template này

```bash
# Clone template
git clone https://github.com/LeHoangTien2510/golden-path-template.git my-new-service
cd my-new-service

# Sửa file values.yaml – điền tên app
#   appName: my-new-service
#   image.repository: lehoangtien2510/my-new-service
```

### 2. Push code lên GitHub

```bash
git init && git add -A && git commit -m "init: from golden path"
git remote add origin https://github.com/LeHoangTien2510/my-new-service.git
git push -u origin main
```

### 3. Tạo ArgoCD Application

```bash
# Copy file mẫu
cp argocd-app.yaml ../../argocd/applications/dev/my-new-service.yaml

# Sửa tên app trong file → commit & push
```

## Tự động có

| Component | Tự động? |
|-----------|---------|
| Docker image | ✅ CI pipeline build & push |
| Helm chart | ✅ Deploy qua ArgoCD |
| Monitoring | ✅ Prometheus scrape metrics |
| Health check | ✅ Liveness + Readiness probe |
| Rollback | ✅ Argo Rollouts canary |
| Logging | ✅ Loki (nếu cài) |

## File cần sửa

| File | Sửa gì |
|------|--------|
| `values.yaml` | `appName`, `image.repository`, `service.port` |
| `Dockerfile` | Port, base image, build command |
| `Jenkinsfile` | Language-specific lint/test |

## Không cần sửa

- CI/CD pipeline → tự có
- Helm chart → tự có
- ArgoCD deploy → tự có
- Monitoring → tự có
