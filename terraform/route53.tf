resource "aws_route53_record" "jenkins_a_record" {
  zone_id = var.aws_route53_zone_id
  name    = "jenkins"
  type    = "A"
  ttl     = 60
  records = [aws_instance.skubestore_jenkins.public_ip]
}

resource "aws_route53_record" "controlplane_a_record" {
  zone_id = var.aws_route53_zone_id
  name    = "controlplane"
  type    = "A"
  ttl     = 60
  records = [aws_instance.skubestore_controlplane.public_ip]
}

resource "aws_route53_record" "node_01_a_record" {
  zone_id = var.aws_route53_zone_id # Replace with your Route 53 Zone ID
  name    = "node-01"
  type    = "A"
  ttl     = 60
  records = [aws_instance.skubestore_node_1.public_ip]
}