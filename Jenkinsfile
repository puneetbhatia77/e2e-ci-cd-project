pipeline {
    agent any
 environment {
        ANSIBLE_INVENTORY = 'inventory.ini'
        DOCKER_IMAGE = 'mynodejs-app'
        ANSIBLE_HOST_KEY_CHECKING = 'False'
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

     stage('Provisioning environment') {  
       def environments = ['dev', 'int', 'prod']
       for (environ in environments) {            
          stage('Provisioning ${environ} environment') {            
            steps {
                dir('terraform') {
                    script {
                        // Initialize Terraform
                        sh 'terraform init'

                        // Create the Azure VM using Terraform
                        sh 'terraform apply -var-file="${environ}.tfvars" -auto-approve'

                        // Retrieve the VM public IP address
                        vmPublicIp = sh(script: 'terraform output -raw public_ip_address', returnStdout: true).trim()
                        username = sh(script: 'terraform output -raw admin_username', returnStdout: true).trim()
                        password = sh(script: 'terraform output -raw admin_password', returnStdout: true).trim()

                        // Write the inventory file
                        writeFile file: "${env.WORKSPACE}/${environ}_${ANSIBLE_INVENTORY}", text: """
                        ${env}
                        ${vmPublicIp}
                        """
                    }
                }
            }
         }  
       }   
         
        stage('Build and Deploy') {
          def environments = ['dev', 'int', 'prod']
          for (environ in environments) {        
            stage('Build and Deploy to ${environ} environment') {
            steps {
                script {
                    withCredentials([usernamePassword(credentialsId:"sshCreds",passwordVariable:"sshPass",usernameVariable:"sshUser")]){
                     sh "ansible-playbook ansible/install-docker.yml -i ${environ}_{env.WORKSPACE}/${ANSIBLE_INVENTORY} -e ansible_ssh_user=${env.sshUser} -e ansible_ssh_pass=${env.sshPass}"
                     }
                    docker.build("${DOCKER_IMAGE}:${environ}", "-f Dockerfile .")
                    withCredentials([usernamePassword(credentialsId:"DockerHubCreds",passwordVariable:"dockerPass",usernameVariable:"dockerUser")]){
                        sh "docker login -u ${env.dockerUser} -p ${env.dockerPass}"
                        sh "docker tag ${DOCKER_IMAGE}:${environ} ${env.dockerUser}/${DOCKER_IMAGE}:${environ}"
                        sh "docker push ${env.dockerUser}/${DOCKER_IMAGE}:${environ}"
                    
                        withCredentials([usernamePassword(credentialsId:"sshCreds",passwordVariable:"sshPass",usernameVariable:"sshUser")]){                        
                        ansiblePlaybook(
                            playbook: 'ansible/pull-run-docker-image.yml',
                            inventory: '${environ}_${ANSIBLE_INVENTORY}',
                            extraVars: [
                                docker_image: "${env.dockerUser}/${DOCKER_IMAGE}:${environ}"
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
    }
}
