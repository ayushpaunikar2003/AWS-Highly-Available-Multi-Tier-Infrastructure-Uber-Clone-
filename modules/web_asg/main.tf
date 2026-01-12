# 1. Defines the Launch Template for our Public Web Instances
resource "aws_launch_template" "web_lt" {
  name_prefix   = "${var.project_name}-web-lt"
  image_id      = "ami-02d26659fd82cf299" # Ubuntu Linux AMI for ap-south-1
  instance_type = "t3.micro"
  key_name      = var.ec2_key_name

  # This script now correctly installs Apache (a web server)
  user_data = base64encode(<<-EOF
    #!/bin/bash
    apt-get update -y
    apt-get install -y apache2  # Install web server
    apt-get install -y mysql-client # Keep for debugging
    systemctl start apache2
    systemctl enable apache2
    # Create a test page so we know this tier is working
    echo "<h1>Hello from the PUBLIC WEB TIER</h1>" > /var/www/html/index.html
  EOF
  )

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [var.web_asg_sg_id]
  }

  tag_specifications {
    resource_type = "instance"
    tags          = { Name = "${var.project_name}-web-instance" } # Renamed tag
  }
}

# 2. Defines the Auto Scaling Group for the Public Web Tier
resource "aws_autoscaling_group" "web_asg" {
  name_prefix         = "${var.project_name}-web-asg" # Renamed ASG
  vpc_zone_identifier = var.public_subnet_ids
  desired_capacity    = 2
  min_size            = 2
  max_size            = 4 # Allow scaling up to 4
  launch_template {
    id      = aws_launch_template.web_lt.id # Points to our renamed LT
    version = "$Latest"
  }
}

# --- Auto-Scaling Policies and Alarms for the WEB TIER ---

# 3. Policy to scale out (add servers)
resource "aws_autoscaling_policy" "scale_out" {
  name                   = "${var.project_name}-web-scale-out-policy" # Renamed
  autoscaling_group_name = aws_autoscaling_group.web_asg.name # Points to our renamed ASG
  policy_type            = "SimpleScaling"
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = 1  # Add 1 instance
  cooldown               = 300
}

# 4. Policy to scale in (remove servers)
resource "aws_autoscaling_policy" "scale_in" {
  name                   = "${var.project_name}-web-scale-in-policy" # Renamed
  autoscaling_group_name = aws_autoscaling_group.web_asg.name # Points to our renamed ASG
  policy_type            = "SimpleScaling"
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = -1 # Remove 1 instance
  cooldown               = 300
}

# 5. Alarm to trigger the scale-out policy
resource "aws_cloudwatch_metric_alarm" "scale_out_alarm" {
  alarm_name          = "${var.project_name}-web-scale-out-alarm" # Renamed
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 70.0 # If CPU is over 70%

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.web_asg.name # Points to our renamed ASG
  }
  alarm_actions = [aws_autoscaling_policy.scale_out.arn]
}

# 6. Alarm to trigger the scale-in policy
resource "aws_cloudwatch_metric_alarm" "scale_in_alarm" {
  alarm_name          = "${var.project_name}-web-scale-in-alarm" # Renamed
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 20.0 # If CPU is under 20%

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.web_asg.name # Points to our renamed ASG
  }
  alarm_actions = [aws_autoscaling_policy.scale_in.arn]
}