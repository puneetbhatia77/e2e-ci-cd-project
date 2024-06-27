pipeline {
    agent any

    stages {
        stage('Setup Environment') {
            steps {
                // Install required tools on the Jenkins agent
                sh 'sudo apt-get update'
                sh 'sudo apt-get install -y nodejs npm terraform ansible'
            }
        }

        stage('Build') {
            steps {
                // Build the web application
                sh 'npm ci'
                sh 'npm run build'
            }
        }

        stage('Deploy to Development') {
            steps {
                // Deploy the web application to the Development environment
                script {
                    // Use Terraform to create the Development environment
                    sh 'terraform init'
                    sh 'terraform apply -var-file="dev.tfvars" -auto-approve'

                    // Use Ansible to configure the Development environment
                    ansiblePlaybook(
                        playbook: 'ansible/dev-playbook.yml',
                        inventory: 'ansible/hosts'
                    )

                    // Use Docker to deploy the web application to the Development environment
                    dockerBuild(
                        image: 'mywebapp:dev',
                        dockerfile: 'Dockerfile'
                    )
                    dockerPush('mywebapp:dev')
                }
            }
        }

        stage('Deploy to Integration') {
            steps {
                // Deploy the web application to the Integration environment
                script {
                    // Use Terraform to create the Integration environment
                    sh 'terraform init'
                    sh 'terraform apply -var-file="int.tfvars" -auto-approve'

                    // Use Ansible to configure the Integration environment
                    ansiblePlaybook(
                        playbook: 'ansible/int-playbook.yml',
                        inventory: 'ansible/hosts'
                    )

                    // Use Docker to deploy the web application to the Integration environment
                    dockerBuild(
                        image: 'mywebapp:int',
                        dockerfile: 'Dockerfile'
                    )
                    dockerPush('mywebapp:int')
                }
            }
        }

        stage('Deploy to Production') {
            steps {
                // Deploy the web application to the Production environment
                script {
                    // Use Terraform to create the Production environment
                    sh 'terraform init'
                    sh 'terraform apply -var-file="prod.tfvars" -auto-approve'

                    // Use Ansible to configure the Production environment
                    ansiblePlaybook(
                        playbook: 'ansible/prod-playbook.yml',
                        inventory: 'ansible/hosts'
                    )

                    // Use Docker to deploy the web application to the Production environment
                    dockerBuild(
                        image: 'mywebapp:prod',
                        dockerfile: 'Dockerfile'
                    )
                    dockerPush('mywebapp:prod')
                }
            }
        }
    }
}
