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
  iam_instance_profile   = module.vpc.ec2_instance_profile_name

  depends_on = [module.vpc]

    user_data = <<-EOF
             #!/bin/bash
              set -e

              # Update packages
              yum update -y

              # Install Web Server (nginx)
              yum install -y nginx

             # Install AWS CLI (usually preinstalled, ensuring latest) & Sync S3
              yum install -y awscli
              aws s3 sync s3://"${module.vpc.omnifood_website_bucket_name}"/ /usr/share/nginx/html/

              # Enable and Start nginx

              systemctl enable nginx
              systemctl start nginx

              #Install CloudWatch Agent
              yum install -y amazon-cloudwatch-agent

              #Fetch config from SSM and Start the Agent
              # The -s flag starts the agent immediately after fetching config
              /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
                -a fetch-config \
                -m ec2 \
                -c ssm:${module.monitoring.ssm_parameter_name} \
                -s

              # 3. Verify status (optional, checks logs)
              /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a status
                
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