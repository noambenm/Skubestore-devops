#!/bin/bash

set -euo pipefail

# Constants
DEFAULT_POD_CIDR="10.244.0.0/16"
POD_NETWORK_URL="https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml"

# Functions
error_exit() {
    echo "Error: $1" >&2
    echo "Cleaning up the failed setup by resetting kubeadm..."
    sudo kubeadm reset -f || echo "Failed to reset kubeadm. Please check manually."
    exit 1
}

# Get the default IP address of the host
get_host_ip() {
    ip route show default 2>/dev/null | awk '/default via/ {print $9}' || error_exit "Failed to retrieve host IP."
}

# Main logic
main() {
    # Parse arguments or use defaults
    POD_CIDR=${1:-$DEFAULT_POD_CIDR}

    HOST_IP=$(get_host_ip)
    if [[ -z "$HOST_IP" ]]; then
        error_exit "Host IP could not be determined."
    fi

    echo "Initializing kubeadm with the following parameters:"
    echo "  API Server Advertise Address: $HOST_IP"
    echo "  Pod Network CIDR: $POD_CIDR"

    # Initialize kubeadm
    sudo kubeadm init \
        --ignore-preflight-errors='NumCPU' \
        --ignore-preflight-errors='Mem' \
        --apiserver-advertise-address="$HOST_IP" \
        --pod-network-cidr="$POD_CIDR" || error_exit "kubeadm init failed."

    # Configure kubectl for the current user
    echo "Setting up kubeconfig for the current user..."
    mkdir -p "$HOME/.kube"
    sudo cp -i /etc/kubernetes/admin.conf "$HOME/.kube/config"
    sudo chown "$(id -u):$(id -g)" "$HOME/.kube/config"

    # Apply the Flannel CNI network
    echo "Applying the Flannel CNI plugin..."
    kubectl apply -f "$POD_NETWORK_URL" || error_exit "Failed to apply Flannel CNI plugin."

    # Install aws load balancer controller
    echo "Installing aws load balancer controller..."

    sudo snap install helm --classic
    helm repo add eks https://aws.github.io/eks-charts
    helm repo update

    CLUSTER_NAME=$(kubectl -n kube-system get configmap kubeadm-config -o yaml | grep -oP 'clusterName:\s*\K\w+')
    REGION=$(ec2metadata --availability-zone | sed 's/.$//')
    TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
    MAC=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/network/interfaces/macs/ | head -n 1 | tr -d '/')
    VPC_ID=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/network/interfaces/macs/${MAC}/vpc-id)

    helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
    -n kube-system \
    --set clusterName=$CLUSTER_NAME \
    --set region=$REGION \
    --set vpcId=$VPC_ID || error_exit "Failed to install aws load balancer controller."

    echo "Cluster initialization complete. You can now join worker nodes."
}

# Run the script
main "$@"
