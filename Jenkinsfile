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
                sh 'sudo sudo apt-get install -y gnupg software-properties-common curl sshpass'
                sh 'curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -'
                sh 'sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"'
                sh 'curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -'
                sh 'sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"'
                sh 'sudo apt-get install -y nodejs npm terraform ansible docker-ce'
                sh 'sudo systemctl status docker'
                sh 'curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash'
            }
        }

     stage('Provisioning environments') {   
            steps {
              script {
                   // Initialize Terraform
                   dir("terraform") {  
                   sh 'terraform init'
                   def environments = ['dev', 'int', 'prod']
                   for (environ in environments) {            
                      stage("Provisioning ${environ} environment") { 
                        // Create terraform workspace
                        sh "terraform workspace new ${environ}"

                        // Create the Azure VM using Terraform
                        sh "terraform apply -var-file=${environ}.tfvars -auto-approve"

                        // Retrieve the VM public IP address
                        vmPublicIp = sh(script: 'terraform output -raw public_ip_address', returnStdout: true).trim()
                        username = sh(script: 'terraform output -raw admin_username', returnStdout: true).trim()
                        password = sh(script: 'terraform output -raw admin_password', returnStdout: true).trim()

                        sh "rm -f ${env.WORKSPACE}/${environ}_${ANSIBLE_INVENTORY}"
                          
                        // Write the inventory file
                        writeFile file: "${env.WORKSPACE}/${environ}_${ANSIBLE_INVENTORY}", text: """
                        ${vmPublicIp.trim()}
                        """
                      }
                    }
                }
            }
         }  
       }   
         
        stage('Build and Deploy') {          
            steps {
              script {
                def environments = ['dev', 'int', 'prod']
                for (environ in environments) {        
                    stage("Build and Deploy to ${environ} environment") {
                    withCredentials([usernamePassword(credentialsId:"sshCreds",passwordVariable:"sshPass",usernameVariable:"sshUser")]){
                    
                     sh "echo ansible_ssh_user=${env.sshUser.trim()}, ansible_ssh_pass=${env.sshPass.trim()}"

                     sh "cat ${env.WORKSPACE}/${environ}_${ANSIBLE_INVENTORY}"

                     sleep 10
                     sh "ansible-playbook -i ${env.WORKSPACE}/${environ}_${ANSIBLE_INVENTORY} ansible/install-docker.yml  -e ansible_ssh_user=${env.sshUser.trim()} -e ansible_ssh_pass=${env.sshPass.trim()}"
                     }
                    docker.build("${DOCKER_IMAGE}:${environ}", "-f Dockerfile .")
                    withCredentials([usernamePassword(credentialsId:"DockerHubCreds",passwordVariable:"dockerPass",usernameVariable:"dockerUser")]){
                        sh "docker login -u ${env.dockerUser} -p ${env.dockerPass}"
                        sh "docker tag ${DOCKER_IMAGE}:${environ} ${env.dockerUser}/${DOCKER_IMAGE}:${environ}"
                        sh "docker push ${env.dockerUser}/${DOCKER_IMAGE}:${environ}"
                    
                        withCredentials([usernamePassword(credentialsId:"sshCreds",passwordVariable:"sshPass",usernameVariable:"sshUser")]){                        
                        ansiblePlaybook(
                            playbook: "ansible/pull-run-docker-image.yml",
                            inventory: "${environ}_${ANSIBLE_INVENTORY}",
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
