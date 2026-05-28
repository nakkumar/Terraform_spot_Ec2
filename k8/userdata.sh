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
