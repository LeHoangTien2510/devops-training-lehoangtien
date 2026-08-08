#!/bin/bash
# =============================================================================
# vault-init.sh – Init + Unseal Vault + Cấu hình Auth Backends
# =============================================================================
# Chạy SAU KHI terraform apply xong (Vault pods đã Running)
# Usage: bash vault-init.sh
#
# SCRIPT NÀY CHỈ LÀM:
#   1. Init Vault (5 key shares, 3 threshold)
#   2. Unseal 3 pods + Join Raft cluster
#   3. Enable KV v2 secrets engine
#   4. Enable Kubernetes Auth (fallback)
#   5. Enable AppRole Auth → tạo Role ID + Secret ID cho Jenkins
#
# SCRIPT NÀY KHÔNG LÀM:
#   ❌ Không đọc file .env nào (tránh lộ plaintext password)
#   ❌ Không tự động tạo MySQL secret
#
# TẠO SECRET BẰNG TAY (theo yêu cầu của mentor):
#   → Mở Vault UI hoặc dùng vault CLI để nhập password thủ công
#   → Xem hướng dẫn ở cuối output của script này
#
# Kiến trúc:
#   Jenkins (EC2) → Internal NLB → Vault → AppRole Auth → Đọc secret
#   Jenkins tự tạo K8s Secret qua kubectl
# =============================================================================
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "============================================"
echo "  VAULT: INIT + UNSEAL + CONFIGURE AUTH"
echo "  (KHÔNG tự động tạo secret – làm bằng tay)"
echo "============================================"

# ─── 1. Đợi pods Running ───
echo "[1/4] Đợi Vault pods Running..."
kubectl wait --for=jsonpath='{.status.phase}'=Running pod -l app.kubernetes.io/name=vault -n vault --timeout=300s
sleep 10

# ─── 2. Init ───
echo "[2/4] Khởi tạo Vault..."
VAULT_INIT=$(kubectl exec -n vault vault-0 -- vault operator init -key-shares=5 -key-threshold=3 -format=json)
echo "$VAULT_INIT" | python3 -c "
import json,sys
d=json.load(sys.stdin)
print(json.dumps({'unseal_keys_b64':d['unseal_keys_b64'],'root_token':d['root_token']},indent=2))
" > "${SCRIPT_DIR}/vault-credentials.json"
chmod 600 "${SCRIPT_DIR}/vault-credentials.json"
echo "   ✅ Credentials saved to: ${SCRIPT_DIR}/vault-credentials.json"

# ─── 3. Unseal + Join Raft ───
echo "[3/4] Unseal + Join Raft..."
ROOT_TOKEN=$(python3 -c "import json; d=json.load(open('${SCRIPT_DIR}/vault-credentials.json')); print(d['root_token'])")
UNSEAL_KEYS=$(python3 -c "import json; d=json.load(open('${SCRIPT_DIR}/vault-credentials.json')); print('\n'.join(d['unseal_keys_b64'][:3]))")

for key in $UNSEAL_KEYS; do
  kubectl exec -n vault vault-0 -- vault operator unseal "$key" > /dev/null 2>&1
done

sleep 5
kubectl exec -n vault vault-1 -- vault operator raft join http://vault-0.vault-internal:8200 2>/dev/null || true
kubectl exec -n vault vault-2 -- vault operator raft join http://vault-0.vault-internal:8200 2>/dev/null || true

for key in $UNSEAL_KEYS; do
  kubectl exec -n vault vault-1 -- vault operator unseal "$key" > /dev/null 2>&1
  kubectl exec -n vault vault-2 -- vault operator unseal "$key" > /dev/null 2>&1
done
echo "   ✅ All 3 pods unsealed"

# ─── 4. Cấu hình Auth Backends (KHÔNG tạo secret) ───
echo "[4/4] Cấu hình Auth Backends..."

kubectl exec -n vault vault-0 -- sh -c "
export VAULT_TOKEN='${ROOT_TOKEN}'

# ─── Enable KV v2 secrets engine ───
vault secrets enable -path=secret kv-v2 2>/dev/null || true
echo '✅ KV v2 enabled at secret/'

# ═══════════════════════════════════════════════════════════════
# Kubernetes Auth (fallback)
# ═══════════════════════════════════════════════════════════════
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
echo '✅ Kubernetes auth configured'

# ═══════════════════════════════════════════════════════════════
# Jenkins Policy – Đọc tất cả secret cần thiết
# ═══════════════════════════════════════════════════════════════
vault policy write jenkins-pipeline - <<POLICY
path "secret/data/demo-app/*" { capabilities = ["read"] }
path "secret/metadata/demo-app/*" { capabilities = ["read"] }
path "secret/data/common/*" { capabilities = ["read"] }
path "secret/metadata/common/*" { capabilities = ["read"] }
path "auth/token/lookup-self" { capabilities = ["read"] }
POLICY

# ═══════════════════════════════════════════════════════════════
# 🔑 TẠO DEDICATED TOKEN CHO JENKINS (mentor style)
#    Token này có thể dùng trực tiếp với: vault login -no-print <token>
#    Đơn giản hơn AppRole, phù hợp all-in-one pipeline
# ═══════════════════════════════════════════════════════════════
JENKINS_TOKEN=\$(vault token create \
    -policy=jenkins-pipeline \
    -ttl=720h \
    -display-name=jenkins-allinone \
    -format=json | python3 -c 'import json,sys; print(json.load(sys.stdin)[\"auth\"][\"client_token\"])')

echo ''
echo '========================================'
echo '  🔑 JENKINS DEDICATED TOKEN (mentor style)'
echo '========================================'
echo \"TOKEN: \${JENKINS_TOKEN}\"
echo ''
echo '⚠️  LUU TOKEN NAY NGAY! Nó chỉ hiện 1 lần!'
echo '   → Thêm vào Jenkins Credentials:'
echo '     - Secret text: vault-token = '\"\${JENKINS_TOKEN}\"
echo '   → TTL: 720h (30 ngày), hết hạn tự động disable'
echo ''
echo '  💡 Cách dùng trong Jenkins pipeline:'
echo '     withCredentials([string(credentialsId: \"vault-token\", variable: \"VAULT_TOKEN\")]) {'
echo '       vault login -no-print -address=\${VAULT_ADDR} \${VAULT_TOKEN}'
echo '       vault kv get -field=database secret/demo-app/mysql'
echo '     }'
echo '========================================'

# ═══════════════════════════════════════════════════════════════
# AppRole Auth – Giữ lại cho fallback / Jenkins Plugin
# ═══════════════════════════════════════════════════════════════
vault auth enable approle 2>/dev/null || true

vault write auth/approle/role/jenkins \
    token_policies='jenkins-pipeline' \
    token_ttl='1h' \
    token_max_ttl='4h' \
    secret_id_ttl='720h' \
    token_num_uses=0

ROLE_ID=\$(vault read -field=role_id auth/approle/role/jenkins/role-id)
SECRET_ID=\$(vault write -f -field=secret_id auth/approle/role/jenkins/secret-id)

echo ''
echo '========================================'
echo '  🔑 APPROLE CREDENTIALS (fallback)'
echo '========================================'
echo \"ROLE_ID:   \${ROLE_ID}\"
echo \"SECRET_ID: \${SECRET_ID}\"
echo '========================================'
"

# ─── Lấy NLB DNS ───
VAULT_NLB_DNS=$(kubectl get svc vault -n vault -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "")

echo ""
echo "============================================"
echo "  ✅ VAULT SẴN SÀNG (chưa có secret!)"
echo "============================================"
echo ""
echo "  🔐 Vault Internal NLB: http://${VAULT_NLB_DNS:-<đang tạo>}:8200"
echo "  🔑 Root Token:         cat ${SCRIPT_DIR}/vault-credentials.json"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  📋 BƯỚC 1: TẠO COMMON SECRETS (Registry + SonarQube)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  vault kv put secret/common/registry \\"
echo "    dockerhub_user='lehoangtien2510' \\"
echo "    dockerhub_password='<your-dockerhub-token>'"
echo ""
echo "  vault kv put secret/common/tools \\"
echo "    sonarqube_token='<your-sonarqube-token>'"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  📋 BƯỚC 2: TẠO MYSQL SECRET (Project-specific)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  Cách 1: Dùng Vault UI (khuyên dùng)"
echo "  ─────────────────────────────────────"
echo "    kubectl port-forward -n vault svc/vault 8200:8200"
echo "    → Mở trình duyệt: http://localhost:8200"
echo "    → Login với Root Token ở trên"
echo "    → Vào secret/ → Create secret"
echo "    → Path: demo-app/mysql"
echo "    → Add keys:"
echo "        root-password = <nhập password thật>"
echo "        database      = full-stack-ecommerce"
echo "        username      = ecommerceapp"
echo "        password      = <nhập password thật>"
echo ""
echo "  Cách 2: Dùng vault CLI (nhập từng dòng, không lưu file)"
echo "  ─────────────────────────────────────────────────────"
echo "    export VAULT_ADDR=http://<NLB_DNS>:8200"
echo "    export VAULT_TOKEN=\$(cat vault-credentials.json | python3 -c \"import json,sys; print(json.load(sys.stdin)['root_token'])\")"
echo "    vault kv put secret/demo-app/mysql \\"
echo "      root-password='<gõ password thật>' \\"
echo "      database='full-stack-ecommerce' \\"
echo "      username='ecommerceapp' \\"
echo "      password='<gõ password thật>'"
echo ""
echo "  ⚠️  KHÔNG LƯU PASSWORD VÀO FILE .ENV!"
echo "  ⚠️  Gõ trực tiếp vào terminal hoặc Vault UI!"
echo ""
echo "  📋 Jenkins setup:"
echo "     1. Thêm credentials vault-role-id + vault-secret-id (ở trên)"
echo "     2. Cập nhật VAULT_ADDR trong Jenkinsfile = http://${VAULT_NLB_DNS:-<NLB_DNS>}:8200"
echo ""
