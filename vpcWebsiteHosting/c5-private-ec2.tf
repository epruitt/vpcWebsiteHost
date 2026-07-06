# This data source retrieves the latest Amazon Linux 2 AMI ID for use in EC2 instances.
data "aws_ami" "latest_amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

 filter {
    name   = "architecture"
    values = ["x86_64"]
  } 
}

resource "aws_instance" "private_ec2" {
  ami           = data.aws_ami.latest_amazon_linux.id
  instance_type = "t2.micro"
  subnet_id     = element(module.vpc.private_subnet_ids, 0)
  vpc_security_group_ids = [module.vpc.ec2_security_group_id]
  iam_instance_profile   = module.vpc.ec2_instance_profile_arn

    user_data = <<-EOF
             #!/bin/bash
              set -e

              # Update packages
              dnf update -y

              # Install Web Server (nginx)
              dnf install -y nginx

              # Install AWS CLI (usually preinstalled, ensuring latest) & Sync S3
                dnf install -y awscli
              aws s3 sync s3://var.bucket_name/ /usr/share/nginx/html/

              # Enable and Start nginx

              systemctl enable nginx
              systemctl start nginx

              #Install CloudWatch Agent
              dnf install -y amazon-cloudwatch-agent
                
              EOF

  tags = {
    Name        = "${var.environment_name}-private-ec2"
    Environment = var.environment_name
  }
}

resource "aws_lb_target_group_attachment" "web_server" {
  target_group_arn = module.vpc.alb_target_group_arn
  target_id        = aws_instance.private_ec2.id
  port             = 80
  
}