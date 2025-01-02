#!/bin/bash

sudo snap install helm --classic
    
# Install aws load balancer controller
echo "Installing aws load balancer controller..."

helm repo add eks https://aws.github.io/eks-charts
helm repo update

CLUSTER_NAME=$(kubectl -n kube-system get configmap kubeadm-config -o yaml | grep -oP 'clusterName:\s*\K\w+')

helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
-n kube-system \
--set clusterName=$CLUSTER_NAME || error_exit "Failed to install aws load balancer controller."

echo "aws load balancer controller installed successfully."

while true; do
    kubectl get endpoints aws-load-balancer-webhook-service -n kube-system | grep -q "10." && break
    echo "Waiting for webhook to become ready..."
    sleep 5
done
echo "Webhook is ready."
sleep 10

git clone https://github.com/noambenm/Skubestore-devops.git
cd Skubestore-devops/k8s

# Installing kubernetes components
echo "Installing kubernetes components..."
kubectl apply -f namespace.yml
kubectl apply -f aws-ingress-controller.yml
kubectl apply -f external-dns.yml
# Install stage environment

kubectl config set-context --current --namespace=skubestore-stage
kubectl apply -f namespace.yml
kubectl apply -f configmap.yml
kubectl apply -f secret.yml
kubectl apply -f mysql-deployment.yml
kubectl apply -f user-deployment.yml
kubectl apply -f product-deployment.yml
kubectl apply -f order-deployment.yml
kubectl apply -f frontend-deployment.yml

# Install prod environment

kubectl config set-context --current --namespace=skubestore-prod
kubectl apply -f namespace.yml
kubectl apply -f configmap.yml
kubectl apply -f secret.yml
kubectl apply -f mysql-deployment.yml
kubectl apply -f user-deployment.yml
kubectl apply -f product-deployment.yml
kubectl apply -f order-deployment.yml
kubectl apply -f frontend-deployment.yml
