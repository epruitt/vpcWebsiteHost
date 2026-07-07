output "vpc_id" {
  value = module.vpc.vpc_id
  description = "The ID of the created VPC"
}

output "public_subnet_ids" {
  value = module.vpc.public_subnet_ids
  description = "List of public subnets IDs"
}

output "private_subnet_ids" {
  value = module.vpc.private_subnet_ids
  description = "List of private subnets IDs"
}

output "private_subnet_map" {
  value = module.vpc.private_subnet_map
  description = "Map of AZ to Public Subnet ID"
}

output "omnifood_website_bucket_name" {
  value = module.vpc.omnifood_website_bucket_name
  description = "The name of the S3 bucket for Omnifood website assets"
}

output "omnifood_website_bucket_arn" {
  value = module.vpc.omnifood_website_bucket_arn
  description = "The ARN of the S3 bucket for Omnifood website assets"
}

output "omnifood_website_bucket_domain_name" {
  value = module.vpc.omnifood_website_bucket_domain_name
  description = "The domain name of the S3 bucket for Omnifood website assets"
}

output "ec2_role_arn" {
  value = module.vpc.ec2_role_arn
  description = "The ARN of the IAM role for EC2 instances"
}

output "ec2_instance_profile_arn" {
  value = module.vpc.ec2_instance_profile_arn
  description = "The ARN of the IAM instance profile for EC2 instances"
}

output "alb_security_group_id" {
  value = module.vpc.alb_security_group_id
  description = "The security group ID for the Application Load Balancer"
}

output "ec2_security_group_id" {
  value = module.vpc.ec2_security_group_id
  description = "The ID of the private security group for EC2 instances"
}

output "alb_dns_name" {
  value = module.vpc.alb_dns_name
  description = "The DNS name of the Application Load Balancer"
}

output "alb_target_group_arn" {
  value = module.vpc.alb_target_group_arn
  description = "The ARN of the Application Load Balancer target group"
}