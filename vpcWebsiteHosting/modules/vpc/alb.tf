# Application Load Balancer (ALB) 
resource "aws_lb" "app_lb" {
  name               = "${var.environment_name}-app-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = values(aws_subnet.public)[*].id
  tags               = merge(var.tags, {Name = "${var.environment_name}-app-lb"})
  
}

# Target Group for the Application Load Balancer
resource "aws_lb_target_group" "app_tg" {
  name     = "${var.environment_name}-app-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200"
  }
  tags = merge(var.tags, {Name = "${var.environment_name}-app-tg"})
  
}

# Listener for the Application Load Balancer
resource "aws_lb_listener" "app_listener" {
  load_balancer_arn = aws_lb.app_lb.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }

 
}

