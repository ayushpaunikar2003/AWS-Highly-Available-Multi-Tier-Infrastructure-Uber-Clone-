output "ilb_dns_name" {
  description = "The DNS name of the Internal Load Balancer"
  value       = aws_lb.internal.dns_name
}

output "app_tier_target_group_arn" {
  description = "The ARN of the app tier's new target group"
  value       = aws_lb_target_group.app_tier_tg.arn
}