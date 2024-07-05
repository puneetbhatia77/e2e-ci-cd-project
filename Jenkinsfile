pipeline {
    agent any
 environment {
        ANSIBLE_INVENTORY = 'inventory.ini'
        DOCKER_IMAGE = 'mynodejs-app"
    }
    stages {
        stage('Setup Environment') {
            steps {
                sh 'sudo apt-get update'
                sh 'sudo sudo apt-get install -y gnupg software-properties-common curl'
                sh 'curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -'
                sh 'sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"'
                sh 'sudo apt-get install -y nodejs npm terraform ansible'
                sh 'curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash'
            }
        }

        stage('Provisioning and configuring Dev environment') {
            steps {
                dir('terraform') {
                    script {
                        // Initialize Terraform
                        sh 'terraform init'

                        // Create the Azure VM using Terraform
                        sh 'terraform apply -var-file="dev.tfvars" -auto-approve'

                        // Retrieve the VM public IP address
                        vmPublicIp = sh(script: 'terraform output -raw vm_public_ip', returnStdout: true).trim()
                        username = sh(script: 'terraform output -raw admin_username', returnStdout: true).trim()
                        password = sh(script: 'terraform output -raw admin_password', returnStdout: true).trim()

                        // Write the inventory file
                        writeFile file: "${ANSIBLE_INVENTORY}", text: """
                        [my_group]
                        ${vmPublicIp}
                        """
                    }
                }
            }
        }  
         stage('Build and Deploy') {
            steps {
                script {
                    withCredentials([usernamePassword(credentialsId:"sshCreds",passwordVariable:"sshPass",usernameVariable:"sshUser")]){
                     sh "ansible-playbook ansible/install-docker.yml -i ${ANSIBLE_INVENTORY} -e ansible_ssh_user=${env.sshUser} -e ansible_ssh_pass=${env.sshPass}"
                     }
                    docker.build("${DOCKER_IMAGE}:dev", "-f Dockerfile .")
                    withCredentials([usernamePassword(credentialsId:"DockerHubCreds",passwordVariable:"dockerPass",usernameVariable:"dockerUser")]){
                        sh "docker login -u ${env.dockerUser} -p ${env.dockerPass}"
                        sh "docker tag mynodejswebapp:dev ${env.dockerUser}/mynodejswebapp:dev"
                        sh "docker push ${env.dockerUser}/${DOCKER_IMAGE}:dev"
                    
                        withCredentials([usernamePassword(credentialsId:"sshCreds",passwordVariable:"sshPass",usernameVariable:"sshUser")]){                        
                        ansiblePlaybook(
                            playbook: 'ansible/pull-run-docker-image.yml',
                            inventory: '${ANSIBLE_INVENTORY}',
                            extraVars: [
                                docker_image: "${env.dockerUser}/${DOCKER_IMAGE}:dev"
                            ],
                            credentialsId: 'sshCreds'
                            )
                        }
                   }
               }
            }
        }     
    }
}
