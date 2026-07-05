output "vpc_id" {
  value = aws_vpc.main.id
  description = "The ID of the created VPC"
}

output "public_subnet_ids" {
  value = [for s in aws_subnet.public: s.id]
  description = "List of public subnets IDs"
}

output "private_subnet_ids" {
  value = [for s in aws_subnet.private: s.id]
  description = "List of private subnets IDs"
}

output "private_subnet_map" {
  value = {for az, subnet in aws_subnet.private: az => subnet.id}
  description = "Map of AZ to Public Subnet ID"
}

output "Omnifood_website_bucket_name" {
  value = aws_s3_bucket.omnifood_website.bucket
  description = "The name of the S3 bucket for Omnifood website assets"
}

output "Omnifood_website_bucket_arn" {
  value = aws_s3_bucket.omnifood_website.arn
  description = "The ARN of the S3 bucket for Omnifood website assets"
}

output "Omnifood_website_bucket_domain_name" {
  value = aws_s3_bucket.omnifood_website.bucket_domain_name
  description = "The domain name of the S3 bucket for Omnifood website assets"
}

output "ec2_role_arn" {
  value = aws_iam_role.ec2_role.arn
  description = "The ARN of the IAM role for EC2 instances"
}

output "ec2_instance_profile_arn" {
  value = aws_iam_instance_profile.ec2_instance_profile.arn
  description = "The ARN of the IAM instance profile for EC2 instances"
}

output "alb_security_group_id" {
  value = var.alb_security_group_id
  description = "The security group ID for the Application Load Balancer"
}

output "ec2_security_group_id" {
  value = aws_security_group.ec2_sg.id
  description = "The ID of the private security group for EC2 instances"
}