output "application_url" {
  description = "The URL of the main, external load balancer"
  value       = "http://${module.alb.alb_dns_name}"
}

output "internal_app_url" {
  description = "The internal DNS name for the app tier"
  value       = "http://${module.ilb.ilb_dns_name}"
}