#!/bin/bash

# Script to find the Docker Host IP

# Check if Docker is installed and command is available
if ! command -v docker &> /dev/null
then
    echo "Docker could not be found, please install Docker."
    exit 1
fi

# Using Docker to inspect the default bridge network to find the gateway
docker_host_ip=$(docker network inspect bridge --format='{{range .IPAM.Config}}{{.Gateway}}{{end}}')

# Check if an IP address was found
if [[ -z "$docker_host_ip" ]]; then
    echo "Failed to find the Docker host IP address."
else
    echo "Docker host IP address is: $docker_host_ip"
fi
