# =============================================================================
# Jenkins Pipeline: Terraform CI/CD (all-in-one)
# Tự động terraform plan/apply khi push code vào thư mục infra/
#
# Flow:
#   Push vào branch Week-*:
#     → terraform fmt -check → init → plan (comment kết quả)
#   Merge vào main/Week-*:
#     → terraform apply -auto-approve
# =============================================================================

pipeline {
    agent any

    environment {
        AWS_PROFILE      = 'root-lab-2'
        AWS_REGION       = 'us-east-1'
        TF_STATE_BUCKET  = 'terraform-state-devops-lab-tien-v3'
    }

    parameters {
        choice(name: 'ACTION', choices: ['plan', 'apply'], description: 'Terraform action')
        choice(name: 'ENV', choices: ['dev', 'stg', 'prd'], description: 'Environment')
        choice(name: 'LAYER', choices: ['network', 'compute', 'jenkins', 'rancher'], description: 'Infra layer')
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Terraform Fmt Check') {
            steps {
                dir("infra/envs/${params.ENV}/${params.LAYER}") {
                    sh 'terraform fmt -check -recursive || echo "Warning: fmt needed"'
                }
            }
        }

        stage('Terraform Init') {
            steps {
                dir("infra/envs/${params.ENV}/${params.LAYER}") {
                    sh '''
                        terraform init -input=false \
                            -backend-config="bucket=${TF_STATE_BUCKET}" \
                            -backend-config="region=${AWS_REGION}" \
                            -backend-config="profile=${AWS_PROFILE}"
                    '''
                }
            }
        }

        stage('Terraform Plan') {
            when { expression { params.ACTION == 'plan' } }
            steps {
                dir("infra/envs/${params.ENV}/${params.LAYER}") {
                    sh '''
                        terraform plan -input=false -out=tfplan \
                            -var="aws_profile=${AWS_PROFILE}" \
                            -var="aws_region=${AWS_REGION}"
                    '''
                }
            }
        }

        stage('Approval (stg/prd)') {
            when {
                allOf {
                    expression { params.ACTION == 'apply' }
                    expression { params.ENV == 'stg' || params.ENV == 'prd' }
                }
            }
            steps {
                input message: "Approve terraform apply for ${params.ENV}/${params.LAYER}?", ok: 'Apply'
            }
        }

        stage('Terraform Apply') {
            when { expression { params.ACTION == 'apply' } }
            steps {
                dir("infra/envs/${params.ENV}/${params.LAYER}") {
                    sh '''
                        terraform apply -auto-approve -input=false tfplan \
                            -var="aws_profile=${AWS_PROFILE}" \
                            -var="aws_region=${AWS_REGION}"
                    '''
                }
            }
        }
    }

    post {
        always {
            cleanWs()
        }
        success {
            echo "✅ Terraform ${params.ACTION} ${params.ENV}/${params.LAYER} completed"
        }
        failure {
            echo "❌ Terraform ${params.ACTION} ${params.ENV}/${params.LAYER} failed"
        }
    }
}
