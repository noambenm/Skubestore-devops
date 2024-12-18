#!/bin/bash

set -e  # Exit on any error
set -o pipefail  # Fail if any part of a pipeline fails

# Set hostname
HOSTNAME=skubestore-controlplane
echo "Setting hostname to '$HOSTNAME'..."
sudo hostnamectl set-hostname "$HOSTNAME"
echo "Hostname set successfully."

# Define variables
TMP_DIR="/tmp/install-scripts"
CONTAINERD_VERSION="1.7.24"
RUNC_VERSION="v1.2.2"
CNI_VERSION="v1.6.1"

CONTAINERD_FILE="$TMP_DIR/containerd-$CONTAINERD_VERSION-linux-amd64.tar.gz"
RUNC_FILE="$TMP_DIR/runc.amd64"
CNI_FILE="$TMP_DIR/cni-plugins-linux-amd64-$CNI_VERSION.tgz"

CONTAINERD_URL="https://github.com/containerd/containerd/releases/download/v$CONTAINERD_VERSION/$(basename $CONTAINERD_FILE)"
RUNC_URL="https://github.com/opencontainers/runc/releases/download/$RUNC_VERSION/$(basename $RUNC_FILE)"
CNI_URL="https://github.com/containernetworking/plugins/releases/download/$CNI_VERSION/$(basename $CNI_FILE)"

CONTAINERD_INSTALL_PATH="/usr/local"
RUNC_INSTALL_PATH="/usr/local/sbin"
CNI_INSTALL_PATH="/opt/cni/bin"
SYSTEMD_SERVICE_DIR="/usr/lib/systemd/system"

# Cleanup function
cleanup() {
    echo "Performing cleanup..."
    rm -rf $TMP_DIR
    echo "Cleanup completed."
}
trap cleanup EXIT

# Disable swap
echo "Disabling swap..."
sudo swapoff -a
echo "Backing up /etc/fstab to /etc/fstab.bak..."
sudo cp /etc/fstab /etc/fstab.bak
echo "Commenting out swap entries in /etc/fstab..."
sudo sed -i '/\bswap\b/s/^/#/' /etc/fstab
if free -h | grep -i swap | grep -q '0B'; then
    echo "Swap has been disabled successfully."
else
    echo "Swap is still active. Please check /etc/fstab manually."
    exit 1
fi

# Load required kernel modules
echo "Loading required kernel modules..."
sudo modprobe br_netfilter
sudo modprobe overlay

# Verify kernel modules are loaded
if lsmod | grep -q br_netfilter; then
    echo "Kernel module 'br_netfilter' loaded successfully."
else
    echo "Failed to load kernel module 'br_netfilter'. Exiting."
    exit 1
fi
if lsmod | grep -q overlay; then
    echo "Kernel module 'overlay' loaded successfully."
else
    echo "Failed to load kernel module 'overlay'. Exiting."
    exit 1
fi

# Persist kernel modules
echo "Ensuring kernel modules are loaded on boot..."
echo "br_netfilter" | sudo tee -a /etc/modules
echo "overlay" | sudo tee -a /etc/modules

# Configure sysctl parameters for Kubernetes
echo "Configuring sysctl parameters for Kubernetes..."
sudo tee /etc/sysctl.d/99-kubernetes-cri.conf <<EOF > /dev/null
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
EOF
sudo sysctl --system

# Verify sysctl parameters
echo "Verifying sysctl parameters..."
if sysctl net.bridge.bridge-nf-call-iptables | grep -q "= 1"; then
    echo "net.bridge.bridge-nf-call-iptables configured successfully."
else
    echo "Failed to configure net.bridge.bridge-nf-call-iptables. Exiting."
    exit 1
fi
if sysctl net.bridge.bridge-nf-call-ip6tables | grep -q "= 1"; then
    echo "net.bridge.bridge-nf-call-ip6tables configured successfully."
else
    echo "Failed to configure net.bridge.bridge-nf-call-ip6tables. Exiting."
    exit 1
fi
if sysctl net.ipv4.ip_forward | grep -q "= 1"; then
    echo "IPv4 forwarding configured successfully."
else
    echo "Failed to configure IPv4 forwarding. Exiting."
    exit 1
fi

# Create temporary directory
echo "Creating temporary directory: $TMP_DIR..."
mkdir -p $TMP_DIR

# Install containerd
echo "Downloading containerd..."
wget $CONTAINERD_URL -O $CONTAINERD_FILE
echo "Extracting and installing containerd to $CONTAINERD_INSTALL_PATH..."
sudo tar -C $CONTAINERD_INSTALL_PATH -xzf $CONTAINERD_FILE

echo "Setting up containerd systemd service..."
wget https://raw.githubusercontent.com/containerd/containerd/main/containerd.service -O "$TMP_DIR/containerd.service"
sudo mv "$TMP_DIR/containerd.service" $SYSTEMD_SERVICE_DIR

echo "Reloading systemd and enabling containerd service..."
sudo systemctl daemon-reload
sudo systemctl enable --now containerd

echo "Verifying containerd installation..."
containerd --version
echo "Containerd installed successfully."

# Install runc
echo "Downloading and installing runc..."
wget $RUNC_URL -O $RUNC_FILE
sudo install -m 755 $RUNC_FILE $RUNC_INSTALL_PATH/runc

echo "Verifying runc installation..."
runc --version
echo "Runc installed successfully."

# Install CNI plugins
echo "Downloading CNI plugins..."
wget $CNI_URL -O $CNI_FILE
sudo mkdir -p $CNI_INSTALL_PATH
echo "Extracting and installing CNI plugins to $CNI_INSTALL_PATH..."
sudo tar -C $CNI_INSTALL_PATH -xzf $CNI_FILE

if ls $CNI_INSTALL_PATH | grep -q "bridge"; then
    echo "CNI plugins installed successfully."
else
    echo "CNI plugins verification failed. Key plugin binaries not found."
    exit 1
fi

# Configure containerd
echo "Configuring containerd..."
sudo mkdir -p /etc/containerd
sudo bash -c "containerd config default > /etc/containerd/config.toml"
echo "Updating containerd config for SystemdCgroup..."
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' "/etc/containerd/config.toml"
echo "Updating sandbox container image in containerd config..."
sudo sed -i 's/sandbox_image = "registry.k8s.io\/pause:3.8"/sandbox_image = "registry.k8s.io\/pause:3.10"/' "/etc/containerd/config.toml"
sudo systemctl restart containerd
echo "Containerd configured successfully."

# Install Kubernetes components
echo "Installing Kubernetes components (kubelet, kubeadm, kubectl)..."
sudo apt-get update

echo "Installing prerequisites (apt-transport-https, ca-certificates, curl, gpg)..."
sudo apt-get install -y apt-transport-https ca-certificates curl gpg

echo "Setting up Kubernetes APT key and repository..."
if [ ! -d /etc/apt/keyrings ]; then
    sudo mkdir -p -m 755 /etc/apt/keyrings
fi

curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.31/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
sudo chmod 644 /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.31/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list > /dev/null
sudo chmod 644 /etc/apt/sources.list.d/kubernetes.list

echo "Updating package list and installing Kubernetes components..."
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

echo "Enabling and starting kubelet service..."
sudo systemctl enable --now kubelet

# Add kubectl alias and autocompletion
echo "Installing and configuring bash-completion..."
sudo apt-get install -y bash-completion

if ! grep -q "source /usr/share/bash-completion/bash_completion" ~/.bashrc; then
    echo "source /usr/share/bash-completion/bash_completion" >> ~/.bashrc
fi

echo "Setting up kubectl autocompletion..."
kubectl completion bash | sudo tee /etc/bash_completion.d/kubectl > /dev/null
sudo chmod a+r /etc/bash_completion.d/kubectl

if ! grep -q "alias k=kubectl" ~/.bashrc; then
    echo "alias k=kubectl" >> ~/.bashrc
    echo "complete -o default -F __start_kubectl k" >> ~/.bashrc
fi

echo "Reloading .bashrc for current session..."
source ~/.bashrc

sudo apt install cloud-utils -y

echo "Kubernetes components and autocompletion configured successfully."
