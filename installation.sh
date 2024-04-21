#!/bin/bash

# Function to ask user and install Docker and Docker Compose
install_docker() {
    read -p "Do you want to install Docker and Docker Compose? [y/N] " response
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        echo "Installing Docker..."
        curl -fsSL https://get.docker.com -o get-docker.sh
        sh get-docker.sh

        echo "Installing Docker Compose..."
        sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
    else
        echo "Skipping Docker and Docker Compose installation."
    fi
}

# Function to ask user and install Minikube
install_minikube() {
    read -p "Do you want to install Kubernetes using Minikube? [y/N] " response
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        echo "Installing Minikube..."
        curl -Lo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
        chmod +x minikube
        sudo mkdir -p /usr/local/bin/
        sudo install minikube /usr/local/bin/
    else
        echo "Skipping Minikube installation."
    fi
}

# Function to ask user and install Helm
install_helm() {
    read -p "Do you want to install Helm? [y/N] " response
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        echo "Installing Helm..."
        curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
    else
        echo "Skipping Helm installation."
    fi
}

# Function to ask user and install kubectl
install_kubectl() {
    read -p "Do you want to install kubectl? [y/N] " response
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        echo "Installing kubectl..."
        curl -LO "https://storage.googleapis.com/kubernetes-release/release/`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`/bin/linux/amd64/kubectl"
        chmod +x ./kubectl
        sudo mv ./kubectl /usr/local/bin/kubectl
    else
        echo "Skipping kubectl installation."
    fi
}

# Function to ask user and install Python
install_python() {
    read -p "Do you want to install Python? [y/N] " response
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        echo "Installing Python..."
        sudo apt-get update
        sudo apt-get install -y python3 python3-pip
    else
        echo "Skipping Python installation."
    fi
}

# Run installation functions
install_docker
install_minikube
install_helm
install_kubectl
install_python

echo "Installation process completed."
