# ============================================================================
# RDS MODULE - OUTPUTS
# ============================================================================

output "endpoint" {
  description = "Endpoint completo do RDS (host:port)"
  value       = aws_db_instance.wordpress.endpoint
}

output "address" {
  description = "Hostname do RDS (sem porta)"
  value       = aws_db_instance.wordpress.address
}

output "port" {
  description = "Porta do RDS"
  value       = aws_db_instance.wordpress.port
}

output "db_name" {
  description = "Nome do banco de dados"
  value       = aws_db_instance.wordpress.db_name
}

output "username" {
  description = "Usuario master"
  value       = aws_db_instance.wordpress.username
  sensitive   = true
}

output "arn" {
  description = "ARN da instancia RDS"
  value       = aws_db_instance.wordpress.arn
}
