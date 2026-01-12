# 1. ALB Security Group (Our External Front Door)
# Allows HTTP traffic from the internet
resource "aws_security_group" "alb_sg" {
  name        = "${var.project_name}-alb-sg"
  description = "Allow HTTP from internet"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 2. Web Tier Security Group (Our Public Web Servers)
# Allows HTTP from the ALB and SSH (for debugging)
resource "aws_security_group" "web_asg_sg" {
  name        = "${var.project_name}-web-asg-sg"
  description = "Allow HTTP from ALB and SSH"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Allow HTTP from ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  # We will allow SSH from anywhere for now to debug
  ingress {
    description = "Allow SSH from Anywhere (for debugging)"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 3. ILB Security Group (Our Internal Load Balancer)
# Allows HTTP traffic ONLY from our Web Tier
resource "aws_security_group" "ilb_sg" {
  name        = "${var.project_name}-ilb-sg"
  description = "Allow HTTP from Web Tier"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Allow HTTP from Web Tier"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.web_asg_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 4. App Tier Security Group (Our Private App Servers)
# Allows HTTP traffic ONLY from our Internal Load Balancer
resource "aws_security_group" "app_asg_sg" {
  name        = "${var.project_name}-app-asg-sg"
  description = "Allow HTTP from ILB"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Allow HTTP from ILB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.ilb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 5. RDS Security Group (Our Database)
# Allows MySQL traffic ONLY from our App Tier
resource "aws_security_group" "rds_sg" {
  name        = "${var.project_name}-rds-sg"
  description = "Allow MySQL from App Tier"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Allow MySQL from App Tier"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.app_asg_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}