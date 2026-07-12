variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-2"

}

variable "environment_name" {
  description = "Enviroment name used in resource names and tags"
  type        = string
  default     = "dev"

}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"

}

variable "tags" {
  description = "Global tags to apply to all resources"
  type        = map(string)
  default = {
    terraform = "true"
  }

}

variable "subnet_newbits" {
  description = "Number of bits to add to VPC CIDR to generate subnets (e.g., 8 means /24 from /16)"
  type        = number
  default     = 8
}

variable "ec2_role_name" {
  description = "Name of the IAM role for EC2 instances"
  type        = string
}


variable "alert_email" {
  description = "Email address for CloudWatch alarm notifications (SNS subscription)"
  type        = string
}

variable "alb_arn_suffix" {
  description = "ARN suffix of the ALB"
  type        = string
}

variable "target_group_arn_suffix" {
  description = "ARN suffix of the target group"
  type        = string
}

variable "instance_id" {
  description = "ID of the EC2 instance"
  type        = string
}