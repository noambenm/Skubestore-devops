#!/bin/bash

# this is a work around for kubernetes clusters that are not managed in eks,
# and aws load balancer controller expects a providerID to be set containing the az and instance id.

# this script is part of the service that runs it and has to be in /usr/local/bin/patch-node.sh

# this script will patch the providerID of the node with the EC2 instance ID
# 1. Check if the node already has the providerID set
# 2. Fetch EC2 instance metadata
# 3. Apply the patch

# Wait for the Kubernetes API server to become reachable
echo "Waiting for Kubernetes API server to become available..."
until kubectl get nodes &>/dev/null; do
    echo "API server is not ready yet. Retrying in 5 seconds..."
    sleep 5
done

# Fetch EC2 instance metadata
EC2_INSTANCE_ID=$(ec2metadata --instance-id)
EC2_AZ=$(ec2metadata --availability-zone)
HOSTNAME=$(hostname)


# Check if the node already has the providerID set
if kubectl get node "$HOSTNAME" -o json | jq -e '.spec.providerID' | grep -q "aws:///$EC2_AZ/$EC2_INSTANCE_ID"; then
    echo "ProviderID is already set for node $HOSTNAME. Exiting."
    exit 0
fi

# Apply the patch
echo "Patching node $HOSTNAME with providerID aws:///$EC2_AZ/$EC2_INSTANCE_ID..."
if kubectl patch node "$HOSTNAME" -p "{\"spec\":{\"providerID\":\"aws:///$EC2_AZ/$EC2_INSTANCE_ID\"}}"; then
    echo "Successfully patched node $HOSTNAME."
else
    echo "Failed to patch node $HOSTNAME."
    exit 1
fi