#!/bin/bash
# =============================================================================
# install-argocd.sh – Cài đặt ArgoCD lên Kubernetes cluster
# Usage: bash argocd/install-argocd.sh
# =============================================================================
set -euo pipefail

NAMESPACE="argocd"

echo "============================================"
echo "  CÀI ĐẶT ARGOCD"
echo "============================================"

# ---------- 1. Tạo namespace ----------
echo "[1/5] Tạo namespace '${NAMESPACE}'..."
kubectl create namespace ${NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -

# ---------- 2. Cài ArgoCD ----------
echo "[2/5] Cài đặt ArgoCD..."
kubectl apply -n ${NAMESPACE} -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# ---------- 3. Đợi ArgoCD ready ----------
echo "[3/5] Đợi ArgoCD pods sẵn sàng..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-server -n ${NAMESPACE} --timeout=300s

# ---------- 4. Lấy admin password ----------
echo "[4/5] Lấy thông tin đăng nhập..."
ARGO_PWD=$(kubectl -n ${NAMESPACE} get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)

echo ""
echo "============================================"
echo "  ARGOCD ĐÃ SẴN SÀNG"
echo "============================================"
echo ""
echo "  Username : admin"
echo "  Password : ${ARGO_PWD}"
echo ""
echo "============================================"
echo "  TRUY CẬP ARGOCD UI"
echo "============================================"
echo ""
echo "Cách 1 - Port-forward (local):"
echo "  kubectl port-forward svc/argocd-server -n ${NAMESPACE} 8080:443"
echo "  Mở: https://localhost:8080"
echo ""
echo "Cách 2 - Đổi service sang LoadBalancer:"
echo "  kubectl patch svc argocd-server -n ${NAMESPACE} -p '{\"spec\": {\"type\": \"LoadBalancer\"}}'"
echo "  kubectl get svc argocd-server -n ${NAMESPACE}"
echo ""

# ---------- 5. Apply Application manifest ----------
echo "[5/5] Tạo ArgoCD Application (demo-app)..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
kubectl apply -f "${SCRIPT_DIR}/application.yaml"

echo ""
echo "✅ Hoàn tất! ArgoCD sẽ tự động sync demo-app từ Git repo."
echo "   Kiểm tra: kubectl get applications -n ${NAMESPACE}"
