#!/bin/sh

chmod +x install_helm.sh
./install_helm.sh
kubectl apply -f ../k8s/namespace.yml
kubectl apply -f ../k8s/configmap.yml
kubectl apply -f ../k8s/secret.yml
kubectl apply -f ../k8s/mysql-deployment.yml
kubectl apply -f ../k8s/user-deployment.yml
kubectl apply -f ../k8s/product-deployment.yml
kubectl apply -f ../k8s/order-deployment.yml
kubectl apply -f ../k8s/aws-ingress-controller.yml
kubectl apply -f ../k8s/external-dns.yml
