#!/bin/bash
# =============================================================================
# install-tools.sh – Cài các CLI tools cần thiết cho DevOps
# =============================================================================
# Usage: bash install-tools.sh
# =============================================================================
set -euo pipefail

echo "============================================"
echo "  CÀI ĐẶT CLI TOOLS"
echo "============================================"

# ─── Argo Rollouts kubectl plugin ───
echo "[1/3] Cài kubectl-argo-rollouts..."
if command -v kubectl-argo-rollouts &>/dev/null; then
    echo "   ✅ Đã cài: $(kubectl-argo-rollouts version --short 2>/dev/null || echo 'ok')"
else
    curl -sLO https://github.com/argoproj/argo-rollouts/releases/latest/download/kubectl-argo-rollouts-linux-amd64
    chmod +x kubectl-argo-rollouts-linux-amd64
    sudo mv kubectl-argo-rollouts-linux-amd64 /usr/local/bin/kubectl-argo-rollouts
    echo "   ✅ Đã cài kubectl-argo-rollouts"
fi

# ─── ArgoCD CLI ───
echo "[2/3] Cài argocd CLI..."
if command -v argocd &>/dev/null; then
    echo "   ✅ Đã cài: $(argocd version --client --short 2>/dev/null || echo 'ok')"
else
    curl -sSL -o argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
    chmod +x argocd
    sudo mv argocd /usr/local/bin/
    echo "   ✅ Đã cài argocd CLI"
fi

# ─── Helm (nếu chưa có) ───
echo "[3/3] Kiểm tra Helm..."
if command -v helm &>/dev/null; then
    echo "   ✅ Đã cài: $(helm version --short 2>/dev/null)"
else
    curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
    echo "   ✅ Đã cài Helm"
fi

echo ""
echo "============================================"
echo "  HOÀN TẤT!"
echo "============================================"
echo ""
echo "  Tools đã cài:"
echo "    kubectl-argo-rollouts  →  quản lý Blue-Green / Canary"
echo "    argocd                 →  quản lý ArgoCD từ CLI"
echo "    helm                   →  quản lý Helm charts"
echo ""
echo "  Lệnh hữu ích:"
echo "    kubectl argo rollouts dashboard         → Dashboard rollouts (port 3100)"
echo "    kubectl argo rollouts get rollout -A    → Xem tất cả rollouts"
echo "    kubectl argo rollouts promote <name> -n <ns> → Promote Blue-Green"
echo "    argocd login <server> --grpc-web        → Login ArgoCD"
echo ""
