#!/bin/bash
# =============================================================================
# Tự động lấy IP từ Terraform output → điền vào inventory → chạy Ansible
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
INVENTORY="${SCRIPT_DIR}/inventory.ini"

# ─── Jenkins ───
echo "🔍 Lấy Jenkins IP..."
JENKINS_IP=$(cd "${SCRIPT_DIR}/../envs/dev/jenkins" 2>/dev/null && terraform output -raw jenkins_url 2>/dev/null | grep -oP '\d+\.\d+\.\d+\.\d+' || true)
if [ -n "$JENKINS_IP" ]; then
    sed -i "s/jenkins-server ansible_host=[^ ]*/jenkins-server ansible_host=${JENKINS_IP}/" "$INVENTORY"
    echo "   ✅ Jenkins: ${JENKINS_IP}"
else
    echo "   ⚠️  Jenkins chưa được deploy"
fi

# ─── Rancher ───
echo "🔍 Lấy Rancher IP..."
RANCHER_IP=$(cd "${SCRIPT_DIR}/../envs/dev/rancher" 2>/dev/null && terraform output -raw rancher_url 2>/dev/null | grep -oP '\d+\.\d+\.\d+\.\d+' || true)
if [ -n "$RANCHER_IP" ]; then
    sed -i "s/rancher-server ansible_host=[^ ]*/rancher-server ansible_host=${RANCHER_IP}/" "$INVENTORY"
    echo "   ✅ Rancher: ${RANCHER_IP}"
else
    echo "   ⚠️  Rancher chưa được deploy"
fi

echo "✅ Inventory đã cập nhật."
echo ""

# ─── Chạy playbook ───
PLAYBOOK="${1:-jenkins-playbook.yml}"
echo "🚀 Chạy: ansible-playbook -i ${INVENTORY} ${PLAYBOOK}"
echo ""
ansible-playbook -i "$INVENTORY" "$PLAYBOOK"
