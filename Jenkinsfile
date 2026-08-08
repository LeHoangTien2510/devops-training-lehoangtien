// =============================================================================
// Jenkinsfile – CI/CD Pipeline cho AWS EKS
//
// FLOW: Jenkins → Internal NLB → Vault (AppRole via Plugin) → Đọc MySQL secret
//       → kubectl create secret → ArgoCD sync → App dùng K8s Secret
//
// JENKINS GLOBAL CONFIG (1 lần: Manage → Configure System → HashiCorp Vault):
//   Vault URL:  http://<NLB_DNS>:8200
//   Credential: Vault AppRole (role-id + secret-id từ vault-init.sh)
//   K/V Engine Version: 2
//
// CREDENTIALS:
//   + dockerhub-credentials  (username/password)
//   + github-token           (secret text)
//   + sonarqube-token        (secret text)
//
// YÊU CẦU: Docker CLI, Trivy, Git, Java, Maven, kubectl, Vault CLI
// Kubeconfig: docker cp ~/.kube/config jenkins:/var/jenkins_home/.kube/
// =============================================================================
pipeline {
    agent any

    parameters {
        string(name: 'APP_NAME', defaultValue: 'demo-app', description: 'Tên ứng dụng')
        string(name: 'DOCKER_REPO', defaultValue: 'lehoangtien2510/ecommerce-backend', description: 'Docker Hub repo')
        string(name: 'GIT_BRANCH', defaultValue: 'Week-6-ArgoCD', description: 'Branch GitOps')
        choice(name: 'DEPLOY_ENV', choices: ['dev', 'dev+stg', 'dev+stg+prd'], description: 'Deploy environments')
    }

    environment {
        APP_NAME    = "${params.APP_NAME}"
        DOCKER_REPO = "${params.DOCKER_REPO}"
        GIT_BRANCH  = "${params.GIT_BRANCH}"
        IMAGE_TAG   = sh(script: 'git rev-parse --short HEAD', returnStdout: true).trim()
        GITOPS_REPO = 'github.com/lehoangtien2510/devops-training-lehoangtien'

        // Vault Plugin tự động login AppRole + đọc secret
        MYSQL_ROOT_PASSWORD = vault path: 'secret/demo-app/mysql', key: 'root-password'
        MYSQL_DATABASE      = vault path: 'secret/demo-app/mysql', key: 'database'
        MYSQL_USER          = vault path: 'secret/demo-app/mysql', key: 'username'
        MYSQL_PASSWORD      = vault path: 'secret/demo-app/mysql', key: 'password'
    }

    stages {

        stage('Verify Tools') {
            steps {
                sh '''
                    echo "===== Kiểm tra ====="
                    docker --version || exit 1
                    docker info --format '{{.ServerVersion}}' || exit 1
                    trivy --version  || echo "⚠️ Trivy chưa cài"
                    git --version
                    java -version 2>&1 || true
                    mvn --version 2>&1 || echo "⚠️ Maven wrapper"
                    kubectl version --client --short 2>/dev/null || kubectl version --client || echo "⚠️ kubectl"
                    echo "====================="
                '''
            }
        }

        stage('Checkout') { steps { checkout scm } }

        stage('Docker Login') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'dockerhub-credentials',
                    usernameVariable: 'DOCKER_USER',
                    passwordVariable: 'DOCKER_PASS'
                )]) {
                    sh 'echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin'
                }
            }
        }

        // ═══════════════════════════════════════════════════════════════
        // 🔧 CREATE K8S SECRETS (secret đã được Vault Plugin nạp vào env)
        // ═══════════════════════════════════════════════════════════════
        stage('🔧 Create K8s Secrets from Vault') {
            steps {
                script {
                    def namespaces = ['demo-app']
                    if (params.DEPLOY_ENV == 'dev+stg') namespaces += ['demo-app-stg']
                    if (params.DEPLOY_ENV == 'dev+stg+prd') namespaces += ['demo-app-prd']

                    namespaces.each { ns ->
                        sh """
                            kubectl create namespace ${ns} --dry-run=client -o yaml | kubectl apply -f -
                            kubectl create secret generic mysql-secret -n ${ns} \\
                                --from-literal=mysql-root-password="\${MYSQL_ROOT_PASSWORD}" \\
                                --from-literal=mysql-database="\${MYSQL_DATABASE}" \\
                                --from-literal=mysql-user="\${MYSQL_USER}" \\
                                --from-literal=mysql-password="\${MYSQL_PASSWORD}" \\
                                --dry-run=client -o yaml | kubectl apply -f -
                            echo "✅ mysql-secret ready in ${ns}"
                        """
                    }
                }
            }
        }

        stage('Lint Backend') {
            steps {
                dir('src/02-backend_spring-boot-rest-api') {
                    sh 'chmod +x mvnw && ./mvnw checkstyle:check -Dcheckstyle.skip=false || true'
                }
            }
        }

        stage('Lint Frontend') {
            steps {
                dir('src/03-frontend_angular-ecommerce') {
                    sh '''
                        docker run --rm --memory=1g --memory-swap=1g \
                          -v $(pwd):/app -w /app node:18-alpine \
                          sh -c "npm install && npx ng lint --fix" || true
                    '''
                }
            }
        }

        stage('Test & Coverage Backend') {
            steps {
                dir('src/02-backend_spring-boot-rest-api') {
                    sh 'chmod +x mvnw && ./mvnw test jacoco:report'
                }
            }
        }

        stage('Test Frontend') {
            steps {
                dir('src/03-frontend_angular-ecommerce') {
                    sh '''
                        docker run --rm --memory=1g --memory-swap=1g \
                          -v $(pwd):/app -w /app node:18-alpine \
                          sh -c "npm install && npx ng test --watch=false --browsers=ChromeHeadlessNoSandbox" || true
                    '''
                }
            }
        }

        stage('SonarQube Analysis') {
            steps {
                withCredentials([string(credentialsId: 'sonarqube-token', variable: 'SONAR_TOKEN')]) {
                    dir('src/02-backend_spring-boot-rest-api') {
                        sh '''
                            chmod +x mvnw
                            ./mvnw sonar:sonar \
                              -Dsonar.projectKey=demo-app \
                              -Dsonar.host.url=http://sonarqube:9000 \
                              -Dsonar.token=${SONAR_TOKEN}
                        '''
                    }
                }
            }
        }

        stage('Build & Push Backend') {
            steps {
                dir('src/02-backend_spring-boot-rest-api') {
                    sh '''
                        docker build -t ${DOCKER_REPO}:${IMAGE_TAG} -t ${DOCKER_REPO}:latest .
                        docker push ${DOCKER_REPO}:${IMAGE_TAG}
                        docker push ${DOCKER_REPO}:latest
                    '''
                }
            }
        }

        stage('Build & Push Frontend') {
            steps {
                dir('src/03-frontend_angular-ecommerce') {
                    sh '''
                        docker build -t ${DOCKER_REPO}-frontend:${IMAGE_TAG} -t ${DOCKER_REPO}-frontend:latest .
                        docker push ${DOCKER_REPO}-frontend:${IMAGE_TAG}
                        docker push ${DOCKER_REPO}-frontend:latest
                    '''
                }
            }
        }

        stage('Trivy Scan Backend') {
            steps {
                sh '''
                    if command -v trivy &>/dev/null; then
                        trivy image --severity HIGH,CRITICAL ${DOCKER_REPO}:${IMAGE_TAG} \
                        || echo "## CANH BAO: Lo hong!"
                    fi
                '''
            }
        }

        stage('Trivy Scan Frontend') {
            steps {
                sh '''
                    if command -v trivy &>/dev/null; then
                        trivy image --severity HIGH,CRITICAL ${DOCKER_REPO}-frontend:${IMAGE_TAG} \
                        || echo "## CANH BAO: Lo hong!"
                    fi
                '''
            }
        }

        stage('Update GitOps DEV') {
            steps {
                withCredentials([string(credentialsId: 'github-token', variable: 'GITHUB_TOKEN')]) {
                    sh '''
                        sed -i "/^backend:/,/^[a-z]/{s/tag:.*/tag: ${IMAGE_TAG}/}" charts/demo-app/values.yaml
                        sed -i "/^frontend:/,/^[a-z]/{s/tag:.*/tag: ${IMAGE_TAG}/}" charts/demo-app/values.yaml
                        git config user.email "jenkins@devopsedu.vn"
                        git config user.name "Jenkins CI"
                        git remote set-url origin https://${GITHUB_TOKEN}@${GITOPS_REPO}
                        git add charts/demo-app/values.yaml
                        git diff --cached --quiet || git commit -m "[CI] DEV: ${IMAGE_TAG} [skip ci]"
                        git push origin HEAD:${GIT_BRANCH} 2>/dev/null
                    '''
                }
            }
        }

        stage('Promote to STG') {
            when { expression { params.DEPLOY_ENV == 'dev+stg' || params.DEPLOY_ENV == 'dev+stg+prd' } }
            steps {
                withCredentials([string(credentialsId: 'github-token', variable: 'GITHUB_TOKEN')]) {
                    sh '''
                        sed -i "/^backend:/,/^[a-z]/{s/tag:.*/tag: ${IMAGE_TAG}/}" charts/demo-app/values-stg.yaml
                        sed -i "/^frontend:/,/^[a-z]/{s/tag:.*/tag: ${IMAGE_TAG}/}" charts/demo-app/values-stg.yaml
                        git config user.email "jenkins@devopsedu.vn"
                        git config user.name "Jenkins CI"
                        git remote set-url origin https://${GITHUB_TOKEN}@${GITOPS_REPO}
                        git add charts/demo-app/values-stg.yaml
                        git commit -m "[CI] STG: ${IMAGE_TAG} [skip ci]"
                        git push origin HEAD:${GIT_BRANCH} 2>/dev/null
                    '''
                }
            }
        }

        stage('Promote to PRD') {
            when { expression { params.DEPLOY_ENV == 'dev+stg+prd' } }
            steps {
                withCredentials([string(credentialsId: 'github-token', variable: 'GITHUB_TOKEN')]) {
                    sh '''
                        sed -i "/^backend:/,/^[a-z]/{s/tag:.*/tag: ${IMAGE_TAG}/}" charts/demo-app/values-prd.yaml
                        sed -i "/^frontend:/,/^[a-z]/{s/tag:.*/tag: ${IMAGE_TAG}/}" charts/demo-app/values-prd.yaml
                        git config user.email "jenkins@devopsedu.vn"
                        git config user.name "Jenkins CI"
                        git remote set-url origin https://${GITHUB_TOKEN}@${GITOPS_REPO}
                        git add charts/demo-app/values-prd.yaml
                        git commit -m "[CI] PRD: ${IMAGE_TAG} [skip ci]"
                        git push origin HEAD:${GIT_BRANCH} 2>/dev/null
                    '''
                }
            }
        }
    }

    post {
        success { echo '✅ BUILD THÀNH CÔNG! ArgoCD sync → MySQL dùng mysql-secret.' }
        failure { echo '❌ BUILD THẤT BẠI!' }
    }
}
