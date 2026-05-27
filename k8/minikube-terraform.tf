##########################################
#            PROVIDER-AWS                #
##########################################

provider "aws" {
  region = "ap-south-2"
}

##########################################
#       MINIKUBE-SERVER-LAUNCH           #
##########################################

resource "aws_instance" "TF-test"{
    ami  = "ami-024ebedf48d280810"
    instance_type = "t3.small"
    subnet_id = "subnet-033bd3dde8b3ed93a"
    key_name = "MT5-DEMO"
    vpc_security_group_ids = ["sg-063db659abab09ea8"]
    user_data = base64encode(<<-EOF
                                #!/bin/bash
                                cd /home/ubuntu

                                ########################################
                                # Install kubectl
                                ########################################

                                curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
                                chmod +x kubectl
                                mv kubectl /usr/local/bin/kubectl

                                ########################################
                                # Install Docker
                                ########################################

                                curl -fsSL https://get.docker.com -o get-docker.sh
                                chmod +x get-docker.sh
                                sh get-docker.sh
                                systemctl enable --now docker

                                ########################################
                                # Add ubuntu user to docker group
                                ########################################

                                usermod -aG docker ubuntu

                                ########################################
                                # Install Minikube
                                ########################################

                                curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
                                chmod +x minikube-linux-amd64
                                mv minikube-linux-amd64 /usr/local/bin/minikube

                                ########################################
                                # Create required directories
                                ########################################

                                mkdir -p /home/ubuntu/.kube
                                mkdir -p /home/ubuntu/.minikube

                                ########################################
                                # Set ownership
                                ########################################

                                chown -R ubuntu:ubuntu /home/ubuntu/.kube
                                chown -R ubuntu:ubuntu /home/ubuntu/.minikube

                                ########################################
                                # Start Minikube as ubuntu user
                                ########################################

                                sudo -u ubuntu minikube start --driver=docker
              EOF
    )
  tags = {
    Name = "MiniKube-k8"
  }
}