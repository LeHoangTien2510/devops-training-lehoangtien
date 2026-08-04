# 🛤️ Golden Path

## Golden Path là gì?

Con đường chuẩn để tạo service mới. Mọi service đi theo con đường này sẽ tự động có:

- ✅ CI/CD Pipeline
- ✅ Docker Build & Push
- ✅ ArgoCD GitOps Deploy
- ✅ Prometheus Monitoring
- ✅ Health Checks
- ✅ Argo Rollouts Canary

## Flow

```mermaid
graph LR
    A[Dev tạo repo từ Template] --> B[Code business logic]
    B --> C[Push lên GitHub]
    C --> D[Jenkins CI chạy]
    D --> E[Docker Build & Push]
    E --> F[Update GitOps repo]
    F --> G[ArgoCD tự deploy]
    G --> H[Prometheus scrape metrics]
```

## Template bao gồm

| File | Mục đích |
|------|----------|
| `Dockerfile` | Build container image |
| `Jenkinsfile` | CI/CD pipeline |
| `values.yaml` | Helm chart config |
| `README.md` | Hướng dẫn cho dev |

## Dev chỉ cần làm gì?

1. Sửa `values.yaml`: điền tên app, port
2. Code business logic trong `src/`
3. Push lên GitHub
