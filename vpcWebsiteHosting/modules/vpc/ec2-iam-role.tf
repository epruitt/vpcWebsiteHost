# trust policy for EC2 
data "aws_iam_policy_document" "assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"
  }
}

# create IAM role for EC2
resource "aws_iam_role" "ec2_role" {
  name               = var.ec2_role_name
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
  tags               = var.tags
}

#attach AWS managed policy to the role (SSM)
resource "aws_iam_role_policy_attachment" "ec2_ssm_policy" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

#Least Privilage policy for S3 access
resource "aws_iam_role_policy" "s3_access" {
  name = "${var.ec2_role_name}-s3-access"
  role = aws_iam_role.ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "ListBucket"
        Effect   = "Allow"
        Action   = ["s3:ListBucket"]
        Resource = [aws_s3_bucket.omnifood_website.arn]
      },
      {
        Sid      = "GetObjects"
        Effect   = "Allow"
        Action   = ["s3:GetObject"]
        Resource = ["${aws_s3_bucket.omnifood_website.arn}/*"]
      }
    ]
  })
}

# Cloudwatch IAM Role for the EC2 Instance
resource "aws_iam_role" "cloudwatch_agent_role" {
  name = "cloudwatch-agent-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}



# Instance profile to attach the IAM role to the EC2 instance
resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "${var.ec2_role_name}-instance-profile"
  role = aws_iam_role.ec2_role.name
  tags = var.tags
}

# Give the EC2 role permission to write logs to CloudWatch
resource "aws_iam_role_policy_attachment" "cloudwatch_agent_policy" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"

}