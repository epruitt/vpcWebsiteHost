module "vpc" {
  source = "./modules/vpc"

  environment_name      = var.environment_name
  vpc_cidr              = var.vpc_cidr
  subnet_newbits        = var.subnet_newbits
  tags                  = var.tags
  ec2_role_name         = var.ec2_role_name
  bucket_arn            = var.bucket_arn
  alb_security_group_id = var.alb_security_group_id
}