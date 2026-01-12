# 1. Defines the User Data script for the private app instances
data "template_file" "user_data" {
  template = <<-EOF
    #!/bin/bash
    apt-get update -y
    apt-get install -y apache2
    systemctl start apache2
    systemctl enable apache2
    # This is a different page so we can tell it apart from the web tier
    echo "<h1>Hello from your PRIVATE APP SERVER!</h1>" > /var/www/html/index.html
  EOF
}

# 2. Defines the Launch Template for the private App Tier
resource "aws_launch_template" "app_lt" {
  name_prefix   = "${var.project_name}-app-lt"
  image_id      = "ami-02b8269d5e85954ef" # Ubuntu Linux AMI for ap-south-1
  instance_type = "t3.micro"
  key_name      = var.ec2_key_name
  vpc_security_group_ids = [var.app_asg_sg_id]
  user_data              = base64encode(data.template_file.user_data.rendered)

  tag_specifications {
    resource_type = "instance"
    tags          = { Name = "${var.project_name}-app-instance" }
  }
}

# 3. Defines the Auto Scaling Group for the private App Tier
resource "aws_autoscaling_group" "app_asg" {
  name_prefix         = "${var.project_name}-app-asg"
  vpc_zone_identifier = var.private_subnet_ids
  desired_capacity    = 2
  min_size            = 2
  max_size            = 4
  launch_template {
    id      = aws_launch_template.app_lt.id
    version = "$Latest"
  }
}

# --- Auto-Scaling Policies and Alarms for the APP TIER ---

# 4. Defines the policy to scale out (add instances)
resource "aws_autoscaling_policy" "scale_out" {
  name                   = "${var.project_name}-app-scale-out-policy"
  autoscaling_group_name = aws_autoscaling_group.app_asg.name
  policy_type            = "SimpleScaling"
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = 1  # Add 1 instance
  cooldown               = 300
}

# 5. Defines the policy to scale in (remove instances)
resource "aws_autoscaling_policy" "scale_in" {
  name                   = "${var.project_name}-app-scale-in-policy"
  autoscaling_group_name = aws_autoscaling_group.app_asg.name
  policy_type            = "SimpleScaling"
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = -1 # Remove 1 instance
  cooldown               = 300
}

# 6. Defines the CloudWatch Alarm to trigger scaling out
resource "aws_cloudwatch_metric_alarm" "scale_out_alarm" {
  alarm_name          = "${var.project_name}-app-scale-out-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 70.0 # If CPU is over 70%

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.app_asg.name
  }
  alarm_actions = [aws_autoscaling_policy.scale_out.arn]
}

# 7. Defines the CloudWatch Alarm to trigger scaling in
resource "aws_cloudwatch_metric_alarm" "scale_in_alarm" {
  alarm_name          = "${var.project_name}-app-scale-in-alarm"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 20.0 # If CPU is under 20%

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.app_asg.name
  }
  alarm_actions = [aws_autoscaling_policy.scale_in.arn]
}