# 1. Outputs the name of the Web Tier's Auto Scaling Group
# This is REQUIRED by our root main.tf to attach the Load Balancer.
output "asg_name" {
  description = "The name of the Web Tier Auto Scaling Group"
  value       = aws_autoscaling_group.web_asg.name # Points to our renamed ASG
}

# 2. (Optional) Outputs the Public IPs for debugging
# This finds the instances using the new, correct tag.
data "aws_instances" "web_hosts" {
  instance_tags = {
    Name = "${var.project_name}-web-instance" # Points to our new instance tag
  }
  instance_state_names = ["running"]
  depends_on = [
    aws_autoscaling_group.web_asg # Points to our renamed ASG
  ]
}

output "web_public_ips" {
  description = "A list of public IP addresses for the web tier hosts"
  value       = data.aws_instances.web_hosts.public_ips
}