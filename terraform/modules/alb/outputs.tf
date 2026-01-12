# ============================================================================
# ALB MODULE - OUTPUTS
# ============================================================================

output "alb_id" {
  description = "ID do ALB"
  value       = aws_lb.main.id
}

output "alb_arn" {
  description = "ARN do ALB"
  value       = aws_lb.main.arn
}

output "alb_dns_name" {
  description = "DNS name do ALB"
  value       = aws_lb.main.dns_name
}

output "alb_zone_id" {
  description = "Zone ID do ALB"
  value       = aws_lb.main.zone_id
}

output "target_group_arn" {
  description = "ARN do Target Group"
  value       = aws_lb_target_group.wordpress.arn
}

output "target_group_name" {
  description = "Nome do Target Group"
  value       = aws_lb_target_group.wordpress.name
}
