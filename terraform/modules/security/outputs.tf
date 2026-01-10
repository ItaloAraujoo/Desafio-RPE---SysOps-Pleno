# ============================================================================
# SECURITY MODULE - OUTPUTS
# ============================================================================

output "public_sg_id" {
  description = "ID do Security Group público"
  value       = aws_security_group.public.id
}

output "public_sg_arn" {
  description = "ARN do Security Group público"
  value       = aws_security_group.public.arn
}

output "private_sg_id" {
  description = "ID do Security Group privado"
  value       = aws_security_group.private.id
}

output "private_sg_arn" {
  description = "ARN do Security Group privado"
  value       = aws_security_group.private.arn
}

output "public_nacl_id" {
  description = "ID da NACL pública"
  value       = aws_network_acl.public.id
}

output "private_nacl_id" {
  description = "ID da NACL privada"
  value       = aws_network_acl.private.id
}
