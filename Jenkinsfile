pipeline {
    agent { label 'terraform-agent' } 
    
    options {
        timestamps()
    }

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

        stage('Terraform Format & Validate') {
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
            echo "Pipeline ARES-INFRA ejecutado en agente 'terraform-agent'"
        }
    }
}
