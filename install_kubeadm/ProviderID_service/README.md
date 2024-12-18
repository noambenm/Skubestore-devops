# Kubernetes Node ProviderID Patching

This workaround is designed for Kubernetes clusters not managed in Amazon EKS. The AWS Load Balancer Controller expects a `providerID` to be set for nodes in the following format:

```
providerID: aws:///$EC2_AZ/$EC2_INSTANCE_ID
e.g., providerID: aws:///us-east-1a/i-0b1591dad951eed6f
```

## **Important Requirements**

1. The `patch-node.sh` script and the associated systemd services **must have access to a `kubectl` interface connected to the Kubernetes API**. Without this, the script will not be able to patch the `providerID` for the node.
2. Ensure that the kubeconfig is correctly set up for the root user on worker nodes. Run the following commands **before activating the services**:

```bash
sudo mkdir -p /root/.kube
sudo cp $HOME/.kube/config /root/.kube/config
sudo chown root:root /root/.kube/config
sudo chmod 600 /root/.kube/config
```

---

## Overview

The setup ensures that the `providerID` of a node is automatically patched with the EC2 instance ID during boot or after deploying a new AMI. The implementation includes:

1. A script named `patch-node.sh` to patch the `providerID`.
2. Two systemd service files:
   - `controlplane-patch-node.service` for control plane nodes.
   - `worker-node-patch-node.service` for worker nodes.

---

## Step 1: The `patch-node.sh` Script

Place the `patch-node.sh` script at the following location:

```
/usr/local/bin/patch-node.sh
```

Make the script executable:

```bash
sudo chmod +x /usr/local/bin/patch-node.sh
```

---

## Step 2: The `controlplane-patch-node.service` Systemd Service

Create the systemd service file for control plane nodes at:

```
/etc/systemd/system/controlplane-patch-node.service
```

---

## Step 3: The `worker-node-patch-node.service` Systemd Service

Create the systemd service file for worker nodes at:

```
/etc/systemd/system/worker-node-patch-node.service
```

---

## Step 4: Activate the Appropriate Service

Before activating the service, ensure the kubeconfig is set up for the root user using the commands listed above.

Then, depending on the node type, activate the corresponding service with the following commands:

For the control plane node:

```bash
sudo systemctl daemon-reload
sudo systemctl enable controlplane-patch-node.service
```

For worker nodes:

```bash
sudo systemctl daemon-reload
sudo systemctl enable worker-node-patch-node.service
```

---

## Result

Upon restarting the instance or deploying a new AMI, the appropriate service will ensure that the `providerID` is set correctly for the node.

```plaintext
Node patching process completed!
```
