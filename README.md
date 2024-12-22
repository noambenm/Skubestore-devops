# Skubestore DevOps Repository

Welcome to the **Skubestore DevOps** repository! This repository contains all the necessary resources, configurations, and automation scripts for setting up and managing the infrastructure and CI/CD pipelines for the Skubestore application.

## Repository Structure

The repository is organized into the following directories:

- **`install_kubeadm/`**
  Contains scripts and configurations for setting up a Kubernetes cluster using `kubeadm`.

- **`jenkins_cd/`**
  Contains resources related to Continuous Deployment (CD) pipelines configured in Jenkins.

- **`jenkins_ci/`**
  Contains resources related to Continuous Integration (CI) pipelines configured in Jenkins.

- **`k8s/`**
  Includes Kubernetes manifests and configuration files for deploying the Skubestore application.

- **`running_the_app/`**
  Provides instructions and scripts for running and testing the Skubestore application.

- **`terraform/`**
  Contains Terraform scripts for provisioning the necessary cloud infrastructure.

## Prerequisites

Before using this repository, ensure the following tools are installed on your machine:

- `kubectl` (for managing Kubernetes clusters)
- `kubeadm` (for setting up Kubernetes clusters)
- `terraform` (for infrastructure as code)
- `jenkins` (for CI/CD pipelines)
- Cloud provider CLI (e.g., AWS CLI, Azure CLI, etc., depending on your infrastructure setup)

## Getting Started

### 1. Kubernetes Cluster Setup
Navigate to the `install_kubeadm/` directory and follow the provided scripts to set up a Kubernetes cluster.

```shell
cd install_kubeadm
./setup_cluster.sh
```

### 2. Deploying the Application
Use the Kubernetes manifests in the `k8s/` directory to deploy the Skubestore application:

```shell
cd k8s
kubectl apply -f .
```

### 3. CI/CD Pipelines
- For CI pipelines, refer to the configurations in the `jenkins_ci/` directory.
- For CD pipelines, explore the `jenkins_cd/` directory.

### 4. Infrastructure Provisioning
Use Terraform scripts in the `terraform/` directory to provision your infrastructure:

```shell
cd terraform
terraform init
terraform apply
```

### 5. Running the Application
Refer to the instructions in the `running_the_app/` directory for running and testing the application.

## Contributing

We welcome contributions! Feel free to submit pull requests or report issues.

## License

This repository is licensed under [MIT License](LICENSE). See the `LICENSE` file for more details.

## Questions?

If you have any questions or run into any issues, please feel free to open an issue or contact the repository maintainer.

---
Happy DevOps-ing!
