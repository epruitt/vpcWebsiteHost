module "vpc" {
  source = "./modules/vpc"

  environment_name = var.environment_name
  vpc_cidr         = var.vpc_cidr
  subnet_newbits   = var.subnet_newbits
  tags             = var.tags
  ec2_role_name    = var.ec2_role_name
  instance_id      = aws_instance.private_ec2.id
  alert_email      = var.alert_email
  alb_arn_suffix         = aws_lb.app.arn_suffix
  target_group_arn_suffix = aws_lb_target_group.app.arn_suffix
  aws_region       = var.aws_region
}