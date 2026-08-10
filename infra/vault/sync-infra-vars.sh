#!/bin/bash
# =============================================================================
# sync-infra-vars.sh – Đồng bộ biến Infrastructure từ code → Vault
# =============================================================================
# Chạy SAU KHI vault-init.sh hoàn tất, Vault đã unseal
# Usage: bash infra/vault/sync-infra-vars.sh
#
# Script này đẩy tất cả biến trong terraform.tfvars lên Vault,
# tổ chức theo path: secret/{env}/infrastructure
# =============================================================================
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# ─── Config ───
VAULT_ADDR="${VAULT_ADDR:-http://localhost:8200}"  # port-forward default
ROOT_TOKEN=$(python3 -c "import json; print(json.load(open('${SCRIPT_DIR}/vault-credentials.json'))['root_token'])")

echo "============================================"
echo "  SYNC INFRA VARS → VAULT"
echo "============================================"
echo "Vault: $VAULT_ADDR"
echo ""

# ─── Login ───
vault login -no-print -address="$VAULT_ADDR" "$ROOT_TOKEN"
vault status -address="$VAULT_ADDR" | head -3

# ═══════════════════════════════════════════════════════════════
# DEV ENVIRONMENT
# ═══════════════════════════════════════════════════════════════
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  [1/3] DEV INFRASTRUCTURE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

vault kv put secret/dev/infrastructure \
  aws_profile="root-lab-2" \
  aws_region="us-east-1" \
  environment="dev" \
  cluster_name="eks-devops-lab" \
  cluster_version="1.31" \
  vpc_name="eks-lab-vpc" \
  vpc_cidr="10.0.0.0/16" \
  azs='["us-east-1a","us-east-1b"]' \
  private_subnets='["10.0.1.0/24","10.0.2.0/24"]' \
  public_subnets='["10.0.101.0/24","10.0.102.0/24"]' \
  node_instance_types='["c7i-flex.large"]' \
  node_desired_size="2" \
  node_min_size="1" \
  node_max_size="3" \
  jenkins_instance_type="m7i-flex.large" \
  jenkins_root_volume_size="30" \
  rancher_instance_type="c7i-flex.large" \
  rancher_root_volume_size="50" \
  key_name="KeyPair-2" \
  state_bucket="terraform-state-devops-lab-tien-v3"

echo "✅ DEV infra vars synced to secret/dev/infrastructure"

# ═══════════════════════════════════════════════════════════════
# STG ENVIRONMENT (cùng account, khác tên resource)
# ═══════════════════════════════════════════════════════════════
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  [2/3] STG INFRASTRUCTURE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

vault kv put secret/stg/infrastructure \
  aws_profile="root-lab-2" \
  aws_region="us-east-1" \
  environment="stg" \
  cluster_name="eks-devops-lab-stg" \
  cluster_version="1.31" \
  vpc_name="eks-lab-vpc-stg" \
  vpc_cidr="10.1.0.0/16" \
  azs='["us-east-1a","us-east-1b"]' \
  private_subnets='["10.1.1.0/24","10.1.2.0/24"]' \
  public_subnets='["10.1.101.0/24","10.1.102.0/24"]' \
  node_instance_types='["c7i-flex.large"]' \
  node_desired_size="3" \
  node_min_size="2" \
  node_max_size="5" \
  jenkins_instance_type="m7i-flex.large" \
  jenkins_root_volume_size="50" \
  rancher_instance_type="c7i-flex.large" \
  rancher_root_volume_size="50" \
  key_name="KeyPair-2" \
  state_bucket="terraform-state-devops-lab-tien-v3"

echo "✅ STG infra vars synced to secret/stg/infrastructure"

# ═══════════════════════════════════════════════════════════════
# PRD ENVIRONMENT (production scale)
# ═══════════════════════════════════════════════════════════════
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  [3/3] PRD INFRASTRUCTURE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

vault kv put secret/prd/infrastructure \
  aws_profile="root-lab-2" \
  aws_region="us-east-1" \
  environment="prd" \
  cluster_name="eks-devops-lab-prd" \
  cluster_version="1.31" \
  vpc_name="eks-lab-vpc-prd" \
  vpc_cidr="10.2.0.0/16" \
  azs='["us-east-1a","us-east-1b"]' \
  private_subnets='["10.2.1.0/24","10.2.2.0/24"]' \
  public_subnets='["10.2.101.0/24","10.2.102.0/24"]' \
  node_instance_types='["c6i.large"]' \
  node_desired_size="5" \
  node_min_size="3" \
  node_max_size="10" \
  jenkins_instance_type="m7i-flex.large" \
  jenkins_root_volume_size="100" \
  rancher_instance_type="c7i-flex.large" \
  rancher_root_volume_size="100" \
  key_name="KeyPair-2" \
  state_bucket="terraform-state-devops-lab-tien-v3"

echo "✅ PRD infra vars synced to secret/prd/infrastructure"

# ═══════════════════════════════════════════════════════════════
# VERIFY
# ═══════════════════════════════════════════════════════════════
echo ""
echo "============================================"
echo "  VERIFY: Đọc lại từ Vault"
echo "============================================"
for env in dev stg prd; do
  echo ""
  echo "─── $env ───"
  vault kv get -format=json "secret/${env}/infrastructure" 2>/dev/null \
    | python3 -c "import json,sys; d=json.load(sys.stdin)['data']['data']; print(f\"  cluster: {d['cluster_name']}\n  vpc: {d['vpc_cidr']}\n  nodes: {d['node_desired_size']} x {d['node_instance_types']}\")" \
    || echo "  ⚠️  Failed to read"
done

echo ""
echo "✅ ALL INFRA VARS SYNCED TO VAULT"
echo ""
echo "Cấu trúc Vault:"
echo "  secret/dev/infrastructure  → $(vault kv get -field=cluster_name secret/dev/infrastructure)"
echo "  secret/stg/infrastructure  → $(vault kv get -field=cluster_name secret/stg/infrastructure)"
echo "  secret/prd/infrastructure  → $(vault kv get -field=cluster_name secret/prd/infrastructure)"
