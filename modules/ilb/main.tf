# 1. Defines the Internal Load Balancer (ILB)
resource "aws_lb" "internal" {
  name               = "${var.project_name}-ilb"
  internal           = true # This makes it an INTERNAL (private) load balancer
  load_balancer_type = "application"
  security_groups    = [var.ilb_sg_id]
  subnets            = var.private_subnet_ids # Placed in private subnets

  tags = {
    Name = "${var.project_name}-ilb"
  }
}

# 2. Defines the Target Group for the Private App Tier (app_asg)
resource "aws_lb_target_group" "app_tier_tg" {
  name     = "${var.project_name}-app-tier-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
  }
}

# 3. Listens for traffic and forwards it to the App Tier Target Group
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.internal.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tier_tg.arn
  }
}