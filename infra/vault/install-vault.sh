#!/bin/bash
# =============================================================================
# install-vault.sh – Cài đặt HashiCorp Vault + External Secrets Operator
# =============================================================================
# Kiến trúc:
#   Vault (HA mode with Raft) → ESO → tự động sync → Kubernetes Secrets
#
# Usage:
#   # Tạo file .env từ template:
#   cp vault.env.example vault.env
#   # Sửa password trong vault.env
#   vim vault.env
#   # Chạy:
#   source vault.env && bash install-vault.sh
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NAMESPACE_VAULT="vault"
NAMESPACE_ESO="external-secrets"

# ─── Đọc secrets từ environment variables ───
# Nếu không set thì báo lỗi, tránh dùng default password
MYSQL_ROOT_PASSWORD="${MYSQL_ROOT_PASSWORD:?❌ Phải set MYSQL_ROOT_PASSWORD (source vault.env)}"
MYSQL_PASSWORD="${MYSQL_PASSWORD:?❌ Phải set MYSQL_PASSWORD (source vault.env)}"
MYSQL_DATABASE="${MYSQL_DATABASE:-full-stack-ecommerce}"
MYSQL_USER="${MYSQL_USER:-ecommerceapp}"

echo "============================================"
echo "  CÀI ĐẶT HASHICORP VAULT + ESO"
echo "============================================"

# --------------- 1. Thêm Helm repos ---------------
echo "[1/8] Thêm Helm repositories..."
helm repo add hashicorp https://helm.releases.hashicorp.com 2>/dev/null || true
helm repo add external-secrets https://charts.external-secrets.io 2>/dev/null || true
helm repo update

# --------------- 2. Tạo namespaces ---------------
echo "[2/8] Tạo namespaces..."
kubectl create namespace ${NAMESPACE_VAULT} --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace ${NAMESPACE_ESO} --dry-run=client -o yaml | kubectl apply -f -

# --------------- 3. Cài đặt Vault (HA mode với Raft storage) ---------------
echo "[3/8] Cài đặt Vault (HA mode)..."
helm upgrade --install vault hashicorp/vault \
  --namespace ${NAMESPACE_VAULT} \
  --values "${SCRIPT_DIR}/vault-values.yaml" \
  --wait --timeout 10m

# --------------- 4. Khởi tạo Vault (init + unseal) ---------------
echo "[4/8] Khởi tạo Vault..."
kubectl -n ${NAMESPACE_VAULT} wait --for=condition=ready pod -l app.kubernetes.io/name=vault --timeout=120s

# Init Vault (5 key shares, 3 key threshold)
VAULT_INIT=$(kubectl exec -n ${NAMESPACE_VAULT} vault-0 -- vault operator init \
  -key-shares=5 \
  -key-threshold=3 \
  -format=json 2>/dev/null)

# Lưu unseal keys + root token vào file an toàn
UNSEAL_KEYS_FILE="${SCRIPT_DIR}/vault-credentials.json"
echo "$VAULT_INIT" | python3 -c "
import json,sys
d = json.load(sys.stdin)
print(json.dumps({
    'unseal_keys_b64': d['unseal_keys_b64'],
    'unseal_keys_hex': d['unseal_keys_hex'],
    'root_token': d['root_token']
}, indent=2))
" > "$UNSEAL_KEYS_FILE"
chmod 600 "$UNSEAL_KEYS_FILE"

echo "   ✅ Vault credentials saved to: $UNSEAL_KEYS_FILE"
echo "   ⚠️  BACKUP FILE NÀY NGAY! Không commit vào Git!"

# --------------- 5. Unseal Vault ---------------
echo "[5/8] Unseal Vault..."
UNSEAL_KEY_1=$(echo "$VAULT_INIT" | python3 -c "import json,sys; print(json.load(sys.stdin)['unseal_keys_b64'][0])")
UNSEAL_KEY_2=$(echo "$VAULT_INIT" | python3 -c "import json,sys; print(json.load(sys.stdin)['unseal_keys_b64'][1])")
UNSEAL_KEY_3=$(echo "$VAULT_INIT" | python3 -c "import json,sys; print(json.load(sys.stdin)['unseal_keys_b64'][2])")

for key in "$UNSEAL_KEY_1" "$UNSEAL_KEY_2" "$UNSEAL_KEY_3"; do
  kubectl exec -n ${NAMESPACE_VAULT} vault-0 -- vault operator unseal "$key" > /dev/null
done
echo "   ✅ Vault unsealed"

# --------------- 6. Cấu hình Vault Kubernetes Auth ---------------
echo "[6/8] Cấu hình Kubernetes Auth + Policy..."
ROOT_TOKEN=$(echo "$VAULT_INIT" | python3 -c "import json,sys; print(json.load(sys.stdin)['root_token'])")

kubectl exec -n ${NAMESPACE_VAULT} vault-0 -- sh -c "
export VAULT_TOKEN='${ROOT_TOKEN}'

# Enable Kubernetes auth
vault auth enable kubernetes 2>/dev/null || true

# Cấu hình K8s auth
K8S_HOST=\$(vault status -format=json | python3 -c 'import json,sys; print(json.load(sys.stdin)[\"vault_host\"])' 2>/dev/null || echo 'https://kubernetes.default.svc')

vault write auth/kubernetes/config \
  kubernetes_host='https://kubernetes.default.svc' \
  kubernetes_ca_cert=\$(cat /var/run/secrets/kubernetes.io/serviceaccount/ca.crt) \
  issuer='https://kubernetes.default.svc.cluster.local'

# Tạo policy cho demo-app
vault policy write demo-app - <<POLICY
path \"secret/data/demo-app/*\" {
  capabilities = [\"read\"]
}
POLICY

# Tạo role cho demo-app namespace
vault write auth/kubernetes/role/demo-app \
  bound_service_account_names='*' \
  bound_service_account_namespaces='demo-app,demo-app-stg,demo-app-prd' \
  policies='demo-app' \
  ttl='1h'

# Enable KV v2 secrets engine
vault secrets enable -path=secret kv-v2 2>/dev/null || true

echo '✅ Vault configured'
"

# --------------- 7. Lưu MySQL secret vào Vault ---------------
echo "[7/8] Lưu MySQL credentials vào Vault..."
kubectl exec -n ${NAMESPACE_VAULT} vault-0 -- sh -c "
export VAULT_TOKEN='${ROOT_TOKEN}'

vault kv put secret/demo-app/mysql \
  root-password='${MYSQL_ROOT_PASSWORD}' \
  database='${MYSQL_DATABASE}' \
  username='${MYSQL_USER}' \
  password='${MYSQL_PASSWORD}'

echo '✅ Secrets stored in Vault: secret/demo-app/mysql'
"

# --------------- 8. Cài đặt External Secrets Operator ---------------
echo "[8/8] Cài đặt External Secrets Operator..."
helm upgrade --install external-secrets external-secrets/external-secrets \
  --namespace ${NAMESPACE_ESO} \
  --set installCRDs=true \
  --wait --timeout 5m

echo ""
echo "============================================"
echo "  CÀI ĐẶT HOÀN TẤT!"
echo "============================================"
echo ""
echo "  Vault UI:  kubectl port-forward -n vault svc/vault 8200:8200"
echo "  Token:     cat ${UNSEAL_KEYS_FILE} | grep root_token"
echo ""
echo "  Secrets đã lưu:"
echo "    vault kv get secret/demo-app/mysql"
echo ""
echo "  ⚠️  QUAN TRỌNG: Backup file ${UNSEAL_KEYS_FILE}"
echo "     Đây là file chứa unseal keys + root token!"
echo ""
