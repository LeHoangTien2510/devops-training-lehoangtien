# 🚀 DevOps Platform

Chào mừng đến với **Internal Developer Platform**!

## Platform này làm gì?

Tạo microservice mới trong **5 phút** mà không cần biết DevOps:

1. Vào [Backstage Portal](/backstage)
2. Click **"Create New Service"**
3. Điền tên app + chọn ngôn ngữ
4. Click **Create**

→ Tự động có: Repo GitHub, CI/CD Pipeline, Docker Build, ArgoCD Deploy, Prometheus Monitoring.

## Kiến trúc

```
Developer → Backstage Portal → Golden Path Template
                                    │
                    ┌───────────────┼───────────────┐
                    ▼               ▼               ▼
              GitHub Repo     Jenkins CI/CD    ArgoCD Deploy
                                    │               │
                                    ▼               ▼
                              Docker Hub      EKS Cluster
                                                    │
                                    ┌───────────────┼───────────────┐
                                    ▼               ▼               ▼
                              Prometheus       Grafana        Argo Rollouts
```

## Services

| Service | URL |
|---------|-----|
| Backstage | `/backstage` |
| Grafana | `/grafana` |
| ArgoCD | `https://localhost:8443` |
| Demo App | ALB DNS |
