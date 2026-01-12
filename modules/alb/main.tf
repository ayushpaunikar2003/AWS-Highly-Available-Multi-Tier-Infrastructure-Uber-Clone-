# 1. Defines the External Application Load Balancer (ALB)
resource "aws_lb" "main" {
  name               = "${var.project_name}-alb"
  internal           = false # 'false' means it is internet-facing
  load_balancer_type = "application"
  security_groups    = [var.alb_sg_id]
  subnets            = var.public_subnet_ids # Placed in public subnets

  tags = { Name = "${var.project_name}-alb" }
}

# 2. Defines the Target Group for the Public Web Tier (web_asg)
resource "aws_lb_target_group" "web_tier_tg" {
  name     = "${var.project_name}-web-tg" # Renamed for clarity
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

# 3. Listens for traffic on Port 80 and forwards it to the Web Tier Target Group
resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_tier_tg.arn # Point to our renamed TG
  }
}