#!/bin/bash
# =============================================================================
# vault-init.sh – Init + Unseal Vault + Lưu MySQL secrets
# =============================================================================
# Chạy SAU KHI terraform apply xong (Vault pods đã Running)
# Usage: bash vault-init.sh
# =============================================================================
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "============================================"
echo "  VAULT: INIT + UNSEAL + STORE SECRETS"
echo "============================================"

# Đợi vault-0 ready
echo "[1/4] Đợi Vault pods ready..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=vault -n vault --timeout=300s

# Init
echo "[2/4] Khởi tạo Vault..."
VAULT_INIT=$(kubectl exec -n vault vault-0 -- vault operator init -key-shares=5 -key-threshold=3 -format=json)
echo "$VAULT_INIT" | python3 -c "
import json,sys
d=json.load(sys.stdin)
print(json.dumps({'unseal_keys_b64':d['unseal_keys_b64'],'root_token':d['root_token']},indent=2))
" > "${SCRIPT_DIR}/vault-credentials.json"
chmod 600 "${SCRIPT_DIR}/vault-credentials.json"

# Unseal các pod
echo "[3/4] Unseal + Join Raft..."
ROOT_TOKEN=$(python3 -c "import json; d=json.load(open('${SCRIPT_DIR}/vault-credentials.json')); print(d['root_token'])")
UNSEAL_KEYS=$(python3 -c "import json; d=json.load(open('${SCRIPT_DIR}/vault-credentials.json')); print('\n'.join(d['unseal_keys_b64'][:3]))")

# Unseal vault-0
for key in $UNSEAL_KEYS; do
  kubectl exec -n vault vault-0 -- vault operator unseal "$key" > /dev/null 2>&1
done

# Join vault-1, vault-2
sleep 5
kubectl exec -n vault vault-1 -- vault operator raft join http://vault-0.vault-internal:8200 2>/dev/null
kubectl exec -n vault vault-2 -- vault operator raft join http://vault-0.vault-internal:8200 2>/dev/null

# Unseal vault-1, vault-2
for key in $UNSEAL_KEYS; do
  kubectl exec -n vault vault-1 -- vault operator unseal "$key" > /dev/null 2>&1
  kubectl exec -n vault vault-2 -- vault operator unseal "$key" > /dev/null 2>&1
done

# Cấu hình K8s auth + lưu secret
echo "[4/4] Cấu hình auth + lưu MySQL secret..."
source "${SCRIPT_DIR}/vault.env" 2>/dev/null || {
  export MYSQL_ROOT_PASSWORD="${MYSQL_ROOT_PASSWORD:-StrongPa55WorD}"
  export MYSQL_PASSWORD="${MYSQL_PASSWORD:-StrongPa55WorD}"
  export MYSQL_DATABASE="${MYSQL_DATABASE:-full-stack-ecommerce}"
  export MYSQL_USER="${MYSQL_USER:-ecommerceapp}"
}

kubectl exec -n vault vault-0 -- sh -c "
export VAULT_TOKEN='${ROOT_TOKEN}'
vault auth enable kubernetes 2>/dev/null || true
vault write auth/kubernetes/config \
  kubernetes_host='https://kubernetes.default.svc' \
  kubernetes_ca_cert=\"\$(cat /var/run/secrets/kubernetes.io/serviceaccount/ca.crt)\" \
  issuer='https://kubernetes.default.svc.cluster.local'
vault policy write demo-app - <<POLICY
path \"secret/data/demo-app/*\" { capabilities = [\"read\"] }
POLICY
vault write auth/kubernetes/role/demo-app \
  bound_service_account_names='*' \
  bound_service_account_namespaces='demo-app,demo-app-stg,demo-app-prd,external-secrets' \
  policies='demo-app' ttl='1h'
vault secrets enable -path=secret kv-v2 2>/dev/null || true
vault kv put secret/demo-app/mysql \
  root-password='${MYSQL_ROOT_PASSWORD}' \
  database='${MYSQL_DATABASE}' \
  username='${MYSQL_USER}' \
  password='${MYSQL_PASSWORD}'
"

echo ""
echo "✅ Vault sẵn sàng!"
echo "   Token:     cat ${SCRIPT_DIR}/vault-credentials.json"
echo "   Secret:    vault kv get secret/demo-app/mysql"
echo ""
echo "⏳ ESO sẽ tự sync trong vài giây → kiểm tra:"
echo "   kubectl get externalsecret -n demo-app"
