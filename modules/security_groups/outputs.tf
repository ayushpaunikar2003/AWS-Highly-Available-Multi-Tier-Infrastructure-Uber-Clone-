output "alb_sg_id" {
  description = "The ID of the ALB's security group"
  value       = aws_security_group.alb_sg.id
}

output "web_asg_sg_id" {
  description = "The ID of the Web ASG's security group"
  value       = aws_security_group.web_asg_sg.id
}

output "ilb_sg_id" {
  description = "The ID of the ILB's security group"
  value       = aws_security_group.ilb_sg.id
}

output "app_asg_sg_id" {
  description = "The ID of the App ASG's security group"
  value       = aws_security_group.app_asg_sg.id
}

output "rds_sg_id" {
  description = "The ID of the RDS's security group"
  value       = aws_security_group.rds_sg.id
}