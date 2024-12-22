resource "aws_security_group" "skubestore_node_sg" {
  name        = "skubestore-node-sg"
  description = "Security group for Skubestore nodes"

  vpc_id = aws_vpc.main.id 

  # Allow all traffic from the same security group
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # -1 means all protocols
    self        = true
    cidr_blocks = []
  }

  # Allow SSH from home IP
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.home_ip]
  }

  # Outbound rules (allow all traffic)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "skubestore-node-sg"
  }
}

resource "aws_security_group" "skubestore_jenkins_sg" {
  name        = "skubestore-jenkins-sg"
  description = "Security group for Skubestore Jenkins"

  vpc_id = aws_vpc.main.id

  # Allow SSH from home IP
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.home_ip]
  }
  # Allow TCP on port 8080 for GitHub IP ranges
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = [
      "89.139.18.223/32",
      "143.55.64.0/20",
      "140.82.112.0/20",
      "192.30.252.0/22",
      "185.199.108.0/22"
    ]
  }

    # Allow TCP on port 8080 for GitHub IPv6 ranges
  ingress {
    from_port        = 8080
    to_port          = 8080
    protocol         = "tcp"
    ipv6_cidr_blocks = [
      "2a0a:a440::/29",
      "2606:50c0::/32"
    ]
  }

  # Outbound rules (allow all traffic)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "skubestore-jenkins-sg"
  }
}

data "aws_ami" "skubestore-controlplane-ami" {
  most_recent = true
  owners      = ["self"] 
  filter {
    name   = "tag:Name"
    values = ["skubestore-controlplane-ami"]
  }
}

data "aws_ami" "skubestore-node_01-ami" {
  most_recent = true
  owners      = ["self"] 
  filter {
    name   = "tag:Name"
    values = ["skubestore-node-01-ami"]
  }
}

data "aws_ami" "skubestore-jenkins-ami" {
  most_recent = true
  owners      = ["self"] 
  filter {
    name   = "tag:Name"
    values = ["skubestore-jenkins-ami"]
  }
}

resource "aws_instance" "skubestore_controlplane" {
  ami                         = data.aws_ami.skubestore-controlplane-ami.id
  instance_type               = var.controlplane_instance_type
  key_name                    = var.keypair
  subnet_id                   = aws_subnet.public_subnet_1.id
  associate_public_ip_address = true

  tags = {
    Name = "skubestore-controlplane"
  }

  private_ip = var.controlplane_ip

  vpc_security_group_ids = [
    aws_security_group.skubestore_node_sg.id
  ]

  iam_instance_profile = aws_iam_instance_profile.skubestore_node_role.name

}

resource "aws_instance" "skubestore_node_1" {
  ami                         = data.aws_ami.skubestore-node_01-ami.id
  instance_type               = var.node_01_instance_type
  key_name                    = var.keypair
  subnet_id                   = aws_subnet.public_subnet_1.id
  associate_public_ip_address = true

  tags = {
    Name = "skubestore-node-01"
  }

  private_ip = var.node_01_ip

  vpc_security_group_ids = [
    aws_security_group.skubestore_node_sg.id
  ]

  iam_instance_profile = aws_iam_instance_profile.skubestore_node_role.name

}

resource "aws_instance" "skubestore_jenkins" {
  ami                         = data.aws_ami.skubestore-jenkins-ami.id
  instance_type               = var.jenkins_instance_type
  key_name                    = var.keypair
  subnet_id                   = aws_subnet.public_subnet_2.id
  associate_public_ip_address = true

  tags = {
    Name = "skubestore-jenkins"
  }

  vpc_security_group_ids = [
    aws_security_group.skubestore_jenkins_sg.id,
    aws_security_group.skubestore_node_sg.id
  ]

  iam_instance_profile = aws_iam_instance_profile.skubestore_node_role.name

}

output "controlplane_public_ip" {
  value = aws_instance.skubestore_controlplane.public_ip
}

output "node_01_public_ip" {
  value = aws_instance.skubestore_node_1.public_ip
}

output "jenkins_public_ip" {
  value = aws_instance.skubestore_jenkins.public_ip
}