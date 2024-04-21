## Overview:
This project demonstrates the deployment of a scalable and highly available backend service on Kubernetes. The service listens for messages from an SQS topic, processes those messages, and stores them in DynamoDB. Both SQS and DynamoDB are simulated locally using LocalStack, providing a robust environment for development.

## Objectives:
- Scalability: Automatically scales in response to the load.
- High Availability: Ensures that the service remains available despite node or data center failures.
- Disruption Tolerance: Maintains availability during cluster upgrades and other disruptions.

## Prerequisites
- Docker and Docker Compose
- Kubernetes cluster (Minikube, Docker Desktop's Kubernetes, or any cloud-based Kubernetes service) along with Metrics Server
- Helm 
- kubectl (configured to interact with your Kubernetes cluster)
- Python 

If you want to install above tools, please execute the provided script for ease, like below
```
chmod +x installation.sh
./installation.sh
```

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
    **Note:** Create a .env file in the project's root directory and include the following variables. The values provided here are for testing purposes only; it is not recommended to use hard-coded values like these in production environments. In a production setting, these variables should be dynamically assigned through a CI/CD pipeline, such as GitLab.
    ```
    AWS_ACCESS_KEY_ID=test
    AWS_SECRET_ACCESS_KEY=test
    AWS_DEFAULT_REGION=us-east-1
    LOCALSTACK_HOST=localstack
    LOCALSTACK_URL=http://localstack:4566
    ```
2. Test the application:
    * ### Via docker-compose:
        - Open docker-compose.yaml and uncomment the commented lines involving **networks** and **app** service and run below command
            ```
            docker-compose up --build
            ```
        - Ensure that the services are functioning properly by checking the docker-compose logs. Look for specific entries in the app service logs indicating that the necessary SQS and DynamoDB table have been created and that the app has successfully connected to LocalStack. This confirms readiness for subsequent operations. Alternatively, you can verify the creation of the SQS and DynamoDB table using the AWS CLI by following these steps:
            + Install AWS CLI using [AWS Official Documentation](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-version.html)
            + Execute aws configure to input dummy values for the access key ID, secret access key, and set the region to **us-east-1**.
            + To confirm the existence of the SQS queue and DynamoDB table in LocalStack, run the following command:
                ```
                - aws --endpoint-url=http://localhost:4566 sqs list-queues --profile dummy --region us-east-1 | cat
                - aws --endpoint-url=http://localhost:4566 dynamodb list-tables --profile dummy --region us-east-1 | cat
                ```
                You should see something like:
                <img width="869" alt="Screenshot 2024-04-22 at 01 06 04" src="https://github.com/samaysinghbisht/scalable-k8s-backend-service/assets/25420937/d0ebdad3-6cd0-4225-8473-9aa74d6c5500">
                <img width="869" alt="Screenshot 2024-04-22 at 01 06 14" src="https://github.com/samaysinghbisht/scalable-k8s-backend-service/assets/25420937/c2815ea4-a909-4544-b541-b5c05735e616">

        - Run below command in your terminal to send a curl request to the app (update the port number if you changed it in the docker-compose.yaml):
            ```
            curl -X POST http://localhost:5001/process_message -H "Content-Type: application/json" -d '{"hello": "world"}'
            ```
        - You should see a success message and along with that log entries in localstack container.
        - Once you are done, take down everything by executing `docker-compose down -v`.

    * ### Via kubernetes:
        - In a production environment, the deployment of applications to Kubernetes is typically automated through a CI/CD pipeline, so manually running the following commands isn't necessary. However, for local testing purposes, you can use the commands below to deploy the application manually:
        - Ensure Helm is installed
        - Start localstack using docker-compose.yaml (make sure the app service and networks configuratiopn is commented) and run command:
            ```
            docker-compose up --build 
            ```
        - Please install the metrics-server in your kubernetes cluster if not installed  already, as it's required by Horizontal Pod Autoscaler, to do that we please run below command:
            ```
            kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
            ```
        
        Note: You may encounter a certificate validation issue for TLS due to the kubelet configuration. While you can resolve this by disabling TLS verification, it is important to note that this approach is not recommended for production environments. To disable TLS verification, you can add a specific flag in the "command" section of the "metrics-server" deployment. Please use the following commands to make this adjustment:
        
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
        
        - Once LocalStack is operational, it's necessary to configure Kubernetes to connect with the LocalStack instance running in Docker Compose. This involves identifying the Docker host IP and updating the **values.env.LOCALSTACK_URL** in our Helm chart's. To accomplish this, you can run the provided Bash script as follows:
            ```
            chmod +x find-docker-host-ip.sh
            ./find-docker-host-ip.sh
            ```

        - Once HELM chart is configured to locate the running LocalStack, you can proceed to deploy the application using the provided Helm chart. To do this, execute the following command:
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
        - You can verify the creation of the SQS and DynamoDB table like you did for docker-compose setup above.

