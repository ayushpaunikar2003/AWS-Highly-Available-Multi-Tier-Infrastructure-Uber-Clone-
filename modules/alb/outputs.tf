output "alb_dns_name" {
  description = "The DNS name of the (External) ALB"
  value       = aws_lb.main.dns_name
}

output "target_group_arn" {
  description = "The ARN of the WEB TIER'S target group"
  value       = aws_lb_target_group.web_tier_tg.arn
}