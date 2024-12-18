# Policy for ALB
resource "aws_iam_policy" "ec2_alb_policy" {
  name        = "ec2-alb-policy"
  path        = "/"
  description = "Policy for ALB permissions"
  policy      = file("iam/ec2-alb-policy.json")
}

# Policy for Route 53
resource "aws_iam_policy" "ec2_route53_policy" {
  name        = "ec2-route53-policy"
  path        = "/"
  description = "Policy for Route 53 permissions"
  policy      = file("iam/ec2-route53-policy.json")
}

# Policy for Secrets Manager
resource "aws_iam_policy" "ec2_secretmanager_policy" {
  name        = "ec2-secretmanager-policy"
  path        = "/"
  description = "Policy for Secrets Manager permissions"
  policy      = file("iam/ec2-secretmanager-policy.json")
}

# IAM Role with Trust Relationship
resource "aws_iam_role" "ec2_role" {
  name               = "ec2-role"
  assume_role_policy = file("iam/ec2-role.json")
}

# Attach Policies to Role
resource "aws_iam_role_policy_attachment" "attach_alb_policy" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.ec2_alb_policy.arn
}

resource "aws_iam_role_policy_attachment" "attach_route53_policy" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.ec2_route53_policy.arn
}

resource "aws_iam_role_policy_attachment" "attach_secretmanager_policy" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.ec2_secretmanager_policy.arn
}

# IAM Instance Profile
resource "aws_iam_instance_profile" "skubestore_node_role" {
  name = "skubestore-node-role"
  role = aws_iam_role.ec2_role.name
}
