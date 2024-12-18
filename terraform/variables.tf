variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  default     = "172.20.0.0/16"
}

variable "public_subnet_1_cidr" {
  description = "CIDR block for the first public subnet"
  default     = "172.20.10.0/24"
}

variable "public_subnet_2_cidr" {
  description = "CIDR block for the second public subnet"
  default     = "172.20.20.0/24"
}

variable "private_subnet_1_cidr" {
  description = "CIDR block for the first private subnet"
  default     = "172.20.30.0/24"
}

variable "private_subnet_2_cidr" {
  description = "CIDR block for the second private subnet"
  default     = "172.20.40.0/24"
}

variable "home_ip" {
  description = "Noams home IP address in CIDR format"
  type        = string
  default     = "89.139.18.223/32"
}

variable "cluster_name" {
  description = "Name of the Kubeadm cluster"
  type        = string
  default     = "kubernetes"
}

variable "keypair" {
  description = "Name of the keypair to use for the instances"
  type        = string
  default     = "main-keypair"
}

variable "controlplane_instance_type" {
  description = "The instance type of the controlplane node."
  type        = string
  default     = "t2.medium"
}

variable "controlplane_ip" {
  description = "The Private IP of the controlplane node, has to be 172.20.10.10"
  type        = string
  default     = "172.20.10.10"
}

variable "node_01_instance_type" {
  description = "The instance type of the node-01 node."
  type        = string
  default     = "t2.medium"
}

variable "node_01_ip" {
  description = "The Private IP of node-01, has to be 172.20.10.20"
  type        = string
  default     = "172.20.10.20"
}

