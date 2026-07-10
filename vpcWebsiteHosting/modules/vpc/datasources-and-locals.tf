# Data Block
data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_region" "current" {
  # Fetch the current AWS region for use in CloudWatch dashboard widgets
}

# Locals Block
locals {
  azs = slice(data.aws_availability_zones.available.names, 0, 3)

  public_subnets = [for k, az in local.azs : cidrsubnet(var.vpc_cidr, var.subnet_newbits, k)]

  private_subnets = [for k, az in local.azs : cidrsubnet(var.vpc_cidr, var.subnet_newbits, k + 10)]
}
