pipeline {
    agent { label 'terraform-agent' }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Terraform Init') {
            steps {
                sh '''
                  terraform init -backend=false
                '''
            }
        }

        stage('Terraform Validate') {
            steps {
                sh '''
                  terraform fmt -check
                  terraform validate
                '''
            }
        }
    }

    post {
        always {
            echo "Pipeline ARES-INFRA ejecutado en agente terraform-agent"
        }
    }
}
