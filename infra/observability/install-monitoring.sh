#!/bin/bash
# =============================================================================
# install-monitoring.sh – Cài đặt toàn bộ monitoring stack lên Kubernetes
# Usage: bash install-monitoring.sh
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NAMESPACE="monitoring"

echo "============================================"
echo "  CÀI ĐẶT MONITORING STACK (kube-prometheus-stack + Loki)"
echo "============================================"

# --------------- 1. Thêm Helm repos ---------------
echo "[1/6] Thêm Helm repositories..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts 2>/dev/null || true
helm repo add grafana https://grafana.github.io/helm-charts 2>/dev/null || true
helm repo update

# --------------- 2. Tạo namespace ---------------
echo "[2/6] Tạo namespace '${NAMESPACE}'..."
kubectl create namespace ${NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -

# --------------- 3. Cài đặt Loki ---------------
echo "[3/6] Cài đặt Loki..."
helm upgrade --install loki grafana/loki \
  --namespace ${NAMESPACE} \
  --values "${SCRIPT_DIR}/loki-values.yaml" \
  --wait --timeout 5m

# --------------- 4. Cài đặt kube-prometheus-stack ---------------
echo "[4/6] Cài đặt kube-prometheus-stack..."
helm upgrade --install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
  --namespace ${NAMESPACE} \
  --values "${SCRIPT_DIR}/kube-prometheus-stack-values.yaml" \
  --wait --timeout 10m

# --------------- 5. Nạp dashboard vào ConfigMap ---------------
echo "[5/6] Nạp dashboards preload..."
# Nginx app dashboard
kubectl create configmap nginx-dashboard \
  --from-file="${SCRIPT_DIR}/dashboards/nginx-dashboard.json" \
  --namespace ${NAMESPACE} \
  --dry-run=client -o yaml | kubectl apply -f -

kubectl label configmap nginx-dashboard \
  --namespace ${NAMESPACE} \
  grafana_dashboard="1" \
  --overwrite

# K8s cluster overview dashboard
kubectl create configmap k8s-cluster-dashboard \
  --from-file="${SCRIPT_DIR}/dashboards/k8s-cluster-overview.json" \
  --namespace ${NAMESPACE} \
  --dry-run=client -o yaml | kubectl apply -f -

kubectl label configmap k8s-cluster-dashboard \
  --namespace ${NAMESPACE} \
  grafana_dashboard="1" \
  --overwrite

# --------------- 6. Lấy thông tin truy cập ---------------
echo "[6/6] Hoàn tất!"
echo ""
echo "============================================"
echo "  THÔNG TIN TRUY CẬP"
echo "============================================"
echo ""
echo "Lấy ALB DNS của Grafana:"
echo "  kubectl get ingress -n ${NAMESPACE} kube-prometheus-stack-grafana -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'"
echo ""
echo "Username: admin"
echo "Password: admin123 (lấy từ secret nếu đã đổi)"
echo ""
echo "Lấy mật khẩu Grafana:"
echo "  kubectl get secret -n ${NAMESPACE} kube-prometheus-stack-grafana -o jsonpath='{.data.admin-password}' | base64 -d"
echo ""
echo "Kiểm tra trạng thái:"
echo "  kubectl get pods -n ${NAMESPACE}"
