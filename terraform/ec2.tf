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

resource "aws_instance" "skubestore_controlplane" {
  ami                         = var.controlplane_ami
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
  ami                         = var.node_01_ami
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
  
output "controlplane_public_ip" {
  value = aws_instance.skubestore_controlplane.public_ip
}

output "node_01_public_ip" {
  value = aws_instance.skubestore_node_1.public_ip
}