# =============================================================================
# HƯỚNG DẪN MIGRATE: GitOps → Push CD (mentor style)
# =============================================================================
# 
# Khi chuyển từ ArgoCD (GitOps) sang Jenkins kubectl set image (Push CD),
# có 1 vấn đề: ArgoCD với selfHeal=true sẽ REVERT image tag về Git.
# 
# Dưới đây là các cách giải quyết.
# =============================================================================

# =============================================================================
# CÁCH 1: TẮT ARGOCD CHO APP DEMO-APP (recommended cho lab)
# =============================================================================
# Xóa ArgoCD Application, giữ tất cả resource trên cluster.
# Jenkins sẽ quản lý toàn bộ deploy lifecycle.

kubectl delete application demo-app -n argocd
# ⚠️  Resource trên cluster vẫn còn, chỉ ArgoCD không quản lý nữa


# =============================================================================
# CÁCH 2: TẮT SELF-HEAL (ArgoCD vẫn sync 1 chiều Git→Cluster)
# =============================================================================
# ArgoCD sẽ KHÔNG revert khi Jenkins kubectl set image

apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: demo-app
  namespace: argocd
spec:
  syncPolicy:
    automated:
      prune: false       # Không xóa resource ngoài Git  
      selfHeal: false    # ← TẮT: không revert manual change


# =============================================================================
# CÁCH 3: ARGOCD IGNORE IMAGE DIFF (ArgoCD vẫn selfHeal các thứ khác)
# =============================================================================
# ArgoCD bỏ qua sự khác biệt về image tag, vẫn selfHeal các field khác

apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: demo-app
  namespace: argocd
spec:
  ignoreDifferences:
    - group: apps
      kind: Deployment
      jsonPointers:
        - /spec/template/spec/containers/0/image
    - group: argoproj.io
      kind: Rollout
      jsonPointers:
        - /spec/template/spec/containers/0/image


# =============================================================================
# CÁCH 4: GIỮ ARGOCD NHƯNG DÙNG KUBECTL SET IMAGE + GIT PUSH (hybrid)
# =============================================================================
# Jenkins vừa kubectl set image (deploy ngay) vừa git push (cho ArgoCD sync sau)
# → Đây là cách ít rủi ro nhất vì ArgoCD sẽ thấy image đã đúng sẵn

# Trong Jenkinsfile thêm step:
#   kubectl set image ... (deploy ngay)
#   sed values.yaml → git push (để Git đồng bộ với cluster)
#   ArgoCD sẽ thấy "no diff" → không revert


# =============================================================================
# ⚡ QUICK START cho lab hiện tại
# =============================================================================
# 
# Step 1: Tạo Vault token cho Jenkins
#   bash infra/vault/vault-init.sh
#   → Lưu TOKEN: jenkins-allinone → thêm vào Jenkins credential "vault-token"
#
# Step 2: Tạo common secrets trong Vault (Registry + SonarQube)
#   export VAULT_ADDR=http://<NLB_DNS>:8200
#   export VAULT_TOKEN=<root-token>
#
#   vault kv put secret/common/registry \
#     dockerhub_user='lehoangtien2510' \
#     dockerhub_password='<dockerhub-token>'
#
#   vault kv put secret/common/tools \
#     sonarqube_token='<sonarqube-token>'
#
# Step 3: Tạo MySQL secret trong Vault (project-specific)
#   vault kv put secret/demo-app/mysql \
#     root-password='<password>' \
#     database='full-stack-ecommerce' \
#     username='ecommerceapp' \
#     password='<password>'
#
# Step 3: Xử lý ArgoCD conflict
#   kubectl edit application demo-app -n argocd
#   → Đổi selfHeal: true → selfHeal: false
#   HOẶC:
#   kubectl patch application demo-app -n argocd --type merge -p '
#     {"spec":{"syncPolicy":{"automated":{"selfHeal":false}}}}'
#
# Step 4: Copy kubeconfig vào Jenkins container
#   docker cp ~/.kube/config jenkins:/var/jenkins_home/.kube/config
#   docker exec -u root jenkins chown jenkins:jenkins /var/jenkins_home/.kube/config
#
# Step 5: Lấy Vault NLB DNS
#   kubectl get svc vault -n vault -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
#   → Cập nhật vào Jenkinsfile.allinone parameter VAULT_ADDR
#
# Step 6: Tạo Jenkins job mới
#   → Copy nội dung Jenkinsfile.allinone vào Jenkins job mới
#   → Chạy Build with Parameters
