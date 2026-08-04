// =============================================================================
// Jenkinsfile – CI/CD Pipeline cho AWS EKS
// YÊU CẦU HẠ TẦNG JENKINS:
//   - Jenkins container phải được chạy với Docker socket mount:
//       -v /var/run/docker.sock:/var/run/docker.sock
//   - Jenkins container cần có: docker CLI, trivy, git
//   - Xem Dockerfile.jenkins để build image chuẩn
//   - Credentials trong Jenkins:
//       + dockerhub-credentials  (username/password)
//       + github-token           (secret text)
// =============================================================================
pipeline {
    agent any

    parameters {
        string(name: 'APP_NAME', defaultValue: 'demo-app', description: 'Tên ứng dụng')
        string(name: 'DOCKER_REPO', defaultValue: 'lehoangtien2510/ecommerce-backend', description: 'Docker Hub repo (vd: lehoangtien2510/my-app)')
        string(name: 'GIT_BRANCH', defaultValue: 'Week-6-ArgoCD', description: 'Branch GitOps để update tag')
        choice(name: 'DEPLOY_ENV', choices: ['dev', 'dev+stg', 'dev+stg+prd'], description: 'Deploy to which environments?')
    }

    environment {
        APP_NAME    = "${params.APP_NAME}"
        DOCKER_REPO = "${params.DOCKER_REPO}"
        GIT_BRANCH  = "${params.GIT_BRANCH}"
        IMAGE_TAG   = sh(script: 'git rev-parse --short HEAD', returnStdout: true).trim()
        GITOPS_REPO = 'github.com/lehoangtien2510/devops-training-lehoangtien'
    }

    stages {

        // ==================== 0. VERIFY TOOLS ====================
        stage('Verify Tools') {
            steps {
                sh '''
                    echo "===== Kiểm tra công cụ ====="
                    echo "Docker CLI:" && docker --version || { echo "❌ THIẾU DOCKER! Jenkins container cần mount /var/run/docker.sock"; exit 1; }
                    echo "Docker daemon:" && docker info --format '{{.ServerVersion}}' || { echo "❌ KHÔNG KẾT NỐI ĐƯỢC DOCKER DAEMON!"; exit 1; }
                    echo "Trivy:"      && trivy --version   || echo "⚠️  Trivy chưa cài – sẽ bỏ qua scan"
                    echo "Git:"        && git --version
                    echo "Java:"       && java -version 2>&1 || true
                    echo "Maven:"      && mvn --version 2>&1 || echo "⚠️  Maven wrapper sẽ tự download"
                    echo "================================"
                '''
            }
        }

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        // ==================== DOCKER LOGIN ====================
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

        // ==================== LINT ====================
        stage('Lint Backend') {
            steps {
                dir('src/02-backend_spring-boot-rest-api') {
                    sh 'chmod +x mvnw'
                    sh './mvnw checkstyle:check -Dcheckstyle.skip=false || true'
                }
            }
        }

        stage('Lint Frontend') {
            steps {
                dir('src/03-frontend_angular-ecommerce') {
                    sh '''
                        docker run --rm --memory=1g --memory-swap=1g -v $(pwd):/app -w /app node:18-alpine \
                          sh -c "npm install && npx ng lint --fix" || true
                    '''
                }
            }
        }

        // ==================== TEST BACKEND + COVERAGE ====================
        stage('Test & Coverage Backend') {
            steps {
                dir('src/02-backend_spring-boot-rest-api') {
                    sh 'chmod +x mvnw'
                    sh './mvnw test jacoco:report'
                }
            }
        }

        stage('Test Frontend') {
            steps {
                dir('src/03-frontend_angular-ecommerce') {
                    sh '''
                        docker run --rm --memory=1g --memory-swap=1g -v $(pwd):/app -w /app node:18-alpine \
                          sh -c "npm install && npx ng test --watch=false --browsers=ChromeHeadlessNoSandbox" || true
                    '''
                }
            }
        }

        // ==================== SONARQUBE ====================
        stage('SonarQube Analysis') {
            steps {
                withCredentials([string(
                    credentialsId: 'sonarqube-token',
                    variable: 'SONAR_TOKEN'
                )]) {
                    dir('src/02-backend_spring-boot-rest-api') {
                        sh '''
                            echo "🔍 SonarQube: Phân tích code quality..."
                            chmod +x mvnw
                            ./mvnw sonar:sonar \
                              -Dsonar.projectKey=demo-app \
                              -Dsonar.projectName='Demo App' \
                              -Dsonar.host.url=http://sonarqube:9000 \
                              -Dsonar.token=${SONAR_TOKEN}
                        '''
                    }
                }
            }
        }

        // ==================== BUILD & PUSH ====================
        stage('Build & Push Backend') {
            steps {
                dir('src/02-backend_spring-boot-rest-api') {
                    sh '''
                        docker build \
                          -t ${DOCKER_REPO}:${IMAGE_TAG} \
                          -t ${DOCKER_REPO}:latest \
                          .
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
                        docker build \
                          -t ${DOCKER_REPO}-frontend:${IMAGE_TAG} \
                          -t ${DOCKER_REPO}-frontend:latest \
                          .
                        docker push ${DOCKER_REPO}-frontend:${IMAGE_TAG}
                        docker push ${DOCKER_REPO}-frontend:latest
                    '''
                }
            }
        }

        // ==================== SECURITY SCAN ====================
        stage('Trivy Scan Backend') {
            steps {
                sh '''
                    if command -v trivy &>/dev/null; then
                        trivy image --severity HIGH,CRITICAL --format table \
                            ${DOCKER_REPO}:${IMAGE_TAG} \
                        || echo "## CANH BAO: Backend co lo hong HIGH/CRITICAL!"
                    else
                        echo "⚠️  Bo qua Trivy scan (chua cai dat)"
                    fi
                '''
            }
        }

        stage('Trivy Scan Frontend') {
            steps {
                sh '''
                    if command -v trivy &>/dev/null; then
                        trivy image --severity HIGH,CRITICAL --format table \
                            ${DOCKER_REPO}-frontend:${IMAGE_TAG} \
                        || echo "## CANH BAO: Frontend co lo hong HIGH/CRITICAL!"
                    else
                        echo "⚠️  Bo qua Trivy scan (chua cai dat)"
                    fi
                '''
            }
        }

        // ==================== GITOPS DEV (auto) ====================
        stage('Update GitOps DEV') {
            steps {
                withCredentials([string(
                    credentialsId: 'github-token',
                    variable: 'GITHUB_TOKEN'
                )]) {
                    sh '''
                        sed -i "/^backend:/,/^[a-z]/{s/tag:.*/tag: ${IMAGE_TAG}/}" charts/demo-app/values.yaml
                        sed -i "/^frontend:/,/^[a-z]/{s/tag:.*/tag: ${IMAGE_TAG}/}" charts/demo-app/values.yaml

                        git config user.email "jenkins@devopsedu.vn"
                        git config user.name "Jenkins CI"
                        git remote set-url origin https://${GITHUB_TOKEN}@${GITOPS_REPO}

                        git add charts/demo-app/values.yaml
                        git diff --cached --quiet || git commit -m "[CI] DEV: Update image tag to ${IMAGE_TAG}"
                        git push origin HEAD:${GIT_BRANCH} 2>/dev/null || echo "## WARNING: Git push failed"
                    '''
                }
            }
        }

        // ==================== PROMOTE TO STG ====================
        stage('Promote to STG') {
            when {
                expression { params.DEPLOY_ENV == 'dev+stg' || params.DEPLOY_ENV == 'dev+stg+prd' }
            }
            steps {
                withCredentials([string(
                    credentialsId: 'github-token',
                    variable: 'GITHUB_TOKEN'
                )]) {
                    sh '''
                        sed -i "/^backend:/,/^[a-z]/{s/tag:.*/tag: ${IMAGE_TAG}/}" charts/demo-app/values-stg.yaml
                        sed -i "/^frontend:/,/^[a-z]/{s/tag:.*/tag: ${IMAGE_TAG}/}" charts/demo-app/values-stg.yaml

                        git config user.email "jenkins@devopsedu.vn"
                        git config user.name "Jenkins CI"
                        git remote set-url origin https://${GITHUB_TOKEN}@${GITOPS_REPO}

                        git add charts/demo-app/values-stg.yaml
                        git commit -m "[CI] STG: Promote image tag to ${IMAGE_TAG}"
                        git push origin HEAD:${GIT_BRANCH} 2>/dev/null || echo "## WARNING: Git push failed"
                    '''
                }
            }
        }

        // ==================== PROMOTE TO PRD ====================
        stage('Promote to PRD') {
            when {
                expression { params.DEPLOY_ENV == 'dev+stg+prd' }
            }
            steps {
                withCredentials([string(
                    credentialsId: 'github-token',
                    variable: 'GITHUB_TOKEN'
                )]) {
                    sh '''
                        sed -i "/^backend:/,/^[a-z]/{s/tag:.*/tag: ${IMAGE_TAG}/}" charts/demo-app/values-prd.yaml
                        sed -i "/^frontend:/,/^[a-z]/{s/tag:.*/tag: ${IMAGE_TAG}/}" charts/demo-app/values-prd.yaml

                        git config user.email "jenkins@devopsedu.vn"
                        git config user.name "Jenkins CI"
                        git remote set-url origin https://${GITHUB_TOKEN}@${GITOPS_REPO}

                        git add charts/demo-app/values-prd.yaml
                        git commit -m "[CI] PRD: Promote image tag to ${IMAGE_TAG}"
                        git push origin HEAD:${GIT_BRANCH} 2>/dev/null || echo "## WARNING: Git push failed"
                    '''
                }
            }
        }
    }

    post {
        success {
            echo '✅ BUILD THÀNH CÔNG! ArgoCD sẽ tự động sync lên AWS EKS.'
        }
        failure {
            echo '❌ BUILD THẤT BẠI! Kiểm tra log ở các stage bên trên.'
        }
    }
}
