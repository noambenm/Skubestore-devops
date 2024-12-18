# Kubernetes Cluster Setup - README

## Overview
This install_kubeadm folder contains two bash scripts designed to automate the setup of a Kubernetes control plane and worker nodes on an EC2-based kubeadm cluster. Below is a high-level view of each script, instructions on how to run them, and guidance on joining worker nodes to the cluster.

### 1. `install_prereq.sh`
This script prepares the environment for Kubernetes installation by performing the following tasks:
- Disables swap and configures the system for Kubernetes.
- Installs necessary dependencies: containerd, runc, CNI plugins.
- Configures containerd with SystemdCgroup and appropriate sandbox container image.
- Installs Kubernetes components: `kubelet`, `kubeadm`, and `kubectl`.
- Configures bash aliases and autocompletion for `kubectl`.

### 2. `controlplane.sh`
This script sets up the control plane node by:
- Initializing the Kubernetes cluster with a specified Pod CIDR (default: `10.244.0.0/16`).
- Configuring kubeconfig for the current user.
- Installing the Flannel CNI plugin for networking.
- Installing the AWS Load Balancer Controller to manage AWS Load Balancers.

## Instructions

### Prerequisites
- Ensure you have access to an EC2 instance running a supported version of Ubuntu.
- The EC2 instance should have internet connectivity to download required components.

### Running `install_prereq.sh` (on all nodes in the cluster)
1. SSH into your EC2 instance.
2. Copy the `install_prereq.sh` script to the instance.
3. Make the script executable:
   ```bash
   chmod +x install_prereq.sh
   ```
4. Run the script as root:
   ```bash
   sudo ./install_prereq.sh
   ```

### Running `controlplane.sh`
1. After completing `install_prereq.sh`, copy the `controlplane.sh` script to the same instance.
2. Make the script executable:
   ```bash
   chmod +x controlplane.sh
   ```
3. Run the script, optionally specifying a custom Pod CIDR:
   ```bash
   sudo ./controlplane.sh
   ```
   By default, the Pod CIDR is set to `10.244.0.0/16`.

## Joining Worker Nodes

After `controlplane.sh` finishes running on the control plane node, a `kubeadm join` command will be displayed in the terminal. This command is used to join worker nodes to the cluster.

### Steps to Join Worker Nodes
1. Copy the `kubeadm join` command displayed after running `controlplane.sh`.
2. SSH into the worker node instance.
3. Run the `install_prereq.sh` script on the worker node as described above.
4. Paste and execute the copied `kubeadm join` command from the control plane node on the worker node:
   ```bash
   sudo kubeadm join <CONTROL_PLANE_IP>:6443 --token <TOKEN> 
       --discovery-token-ca-cert-hash sha256:<HASH>
   ```

### Verifying the Node Join
1. SSH back into the control plane node.
2. Use `kubectl` to verify that the worker node has joined the cluster:
   ```bash
   kubectl get nodes
   ```
   The worker node should appear in the list with a `Ready` status.

## Notes
- The `controlplane.sh` script automatically sets up the Flannel CNI and AWS Load Balancer Controller. Ensure that you have proper AWS IAM permissions and role configurations for these components.
- For troubleshooting, logs for `kubeadm`, `containerd`, and `kubelet` can be found in the system's journal logs:
  ```bash
  sudo journalctl -u kubeadm
  sudo journalctl -u containerd
  sudo journalctl -u kubelet
  ```

By following these steps, you can successfully set up a Kubernetes cluster using the provided scripts.


