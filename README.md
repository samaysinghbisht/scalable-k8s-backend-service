

Pre-Requisite:
Docker should be installed, additionally kubernetes should be configured
Docker-Compose
Python



Add an image for directory structure here


## Overview:
This project demonstrates the deployment of a scalable and highly available backend service on Kubernetes. The service listens for messages from an SQS topic, processes those messages, and stores them in DynamoDB. Both SQS and DynamoDB are simulated locally using LocalStack, providing a robust environment for development.

## Objectives:
- Scalability: Automatically scales in response to the load.
- High Availability: Ensures that the service remains available despite node or data center failures.
- Disruption Tolerance: Maintains availability during cluster upgrades and other disruptions.

## Prerequisites
- Docker and Docker Compose
- Kubernetes cluster (Minikube, Docker Desktop's Kubernetes, or any cloud-based Kubernetes service) along with Metrics Server
- Helm 3
- kubectl (configured to interact with your Kubernetes cluster)
- LocalStack
- Python 3.8+

## Architecture
- Python Backend Service: A simple Python application that listens to messages from an SQS queue and writes data to DynamoDB.
- LocalStack: Used to mock AWS SQS and DynamoDB services locally running in docker-compose.
- Kubernetes: Deploys the backend service ensuring it meets the scalability and availability requirements.

## Steps to deploy:
1. Clone this repository using:
    ```
    git clone https://github.com/samaysinghbisht/scalable-k8s-backend-service.git
    cd  scalable-k8s-backend-service
    ```
2. Test the application:
    * Via docker-compose
        - Open docker-compose.yaml and uncomment the commented lines involving **networks** and **app** service and run below command
        ```
        docker-compose up --build
        ```
        - Ensure that the services are up and running in docker-compose logs, you should see something like below in app service logs, which ensures that the required SQS and DynamoDB table is created and app has access to localstack for next steps:
        - Run below command in your terminal to send a curl request to the app (update the port number if you changed it in the docker-compose.yaml):
        ```
        curl -X POST http://localhost:5001/process_message -H "Content-Type: application/json" -d '{"hello": "world"}'
        ```
    * Via kubernetes:
        - Ensure Helm is installed
        - Start localstack using docker-compose.yaml (make sure the app service and networks configuratiopn is commented) and run command:
        ```
        docker-compose up --build 
        ```
        - Please install the metrics-server in your kubernetes cluster if not installed  already, as it's required by Horizontal Pod Autoscaler, to do that we please run below command:
        ```
        kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
        ```
        
        Note: You could run into an issue with certificate validation for TLS, because of how kubelet is configured, but we can easily fix that by disabling TLS verification, however it is not recommended for prooduction environment, and to do that please add a flag under the "command" section of "metrics-server" deployment, please follow below commands to do that:
        
        ```
        kubectl edit deployment metrics-server -n kube-system
        Now, just add a new flag '--kubelet-insecure-tls' under spec.template.spec.containers like below:
            containers:
            - name: metrics-server
            image: registry.k8s.io/metrics-server/metrics-server:v0.7.1
            args:
                - '--cert-dir=/tmp'
                - '--secure-port=10250'
                - '--kubelet-preferred-address-types=InternalIP,ExternalIP,Hostname'
                - '--kubelet-use-node-status-port'
                - '--metric-resolution=15s'
                - '--kubelet-insecure-tls'
        ```
        
        - Once local stack is up and running we need to let our kuberntes know how it can connect with the localstack running in docker-compose and to do that we have to find the docker host IP and update it in our helm chart values.env.LOCALSTACK_URL, and for that we can simply run the provided bash script, like below:
        ```
        chmod +x find-docker-host-ip.sh
        ./find-docker-host-ip.sh
        ```

        - Once our kubernetes know where localstack is running, let's start with deploying the app using the provided helm chart and to do that run below command:
        ```
        helm install backend-svc backend-svc-helm -n backend-svc
        ```

        It will install the backend service in a namespace "backend-svc"
        - Now we can see the resources in *backend-svc* namespace by running below command:
        ```
        kubectl get all -n backend-svc

        ```
        You should see list of below resources:
        * pods
        * deployment
        * service
        * replicaset
        * HPA
        
        Make sure that your application is working correctly and able to connect with the localstack running in docker-compose, we can check the logs of deployment to make sure SQS queue and Dynamodb table was created, and to do that, please run the command:
        ```
        kubectl logs deployment.apps/backend-svc-backend-svc-helm -n backend-svc 
        ```
   
        - Once everything is up and running we can port forward the service to our desired port and send a curl request to it and see the SQS and DynamoDB entries in action:
        ```
        kubectl port-forward service/backend-svc-backend-svc-helm -n backend-svc 5002:5001
        ```
        - Now, the port-forwarding is working fine, we can send a curl request to our application and see if it can perform the required action, which is sending a message to SQS, parsing it and storing in dynamodb table, to do that run below command:
        ```
        curl -X POST http://localhost:5002/process_message -H "Content-Type: application/json" -d '{"hello": "world"}'
        ```

