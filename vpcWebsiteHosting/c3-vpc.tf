module "vpc" {
  source = "./modules/vpc"

  environment_name      = var.environment_name
  vpc_cidr              = var.vpc_cidr
  subnet_newbits        = var.subnet_newbits
  tags                  = var.tags
  ec2_role_name         = var.ec2_role_name
  aws_region            = var.aws_region
}