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