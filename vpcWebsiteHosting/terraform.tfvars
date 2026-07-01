# Environment & Region 
environment_name = "dev"
aws_region       = "us-east-2"

# CIDR for VPC
vpc_cidr = "10.1.0.0/16"

# Subnet mask (/24 subnets)
subnet_newbits = 8

# Tags 
tags = {
  Terraform   = "true"
  Project     = "Website Hosting"
  Owner       = "E Pruitt"
  Course = "VPC website Hosting"
  Demo = "terraform.tfvars demo"
}