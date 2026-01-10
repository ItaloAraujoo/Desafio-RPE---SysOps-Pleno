# ============================================================================
# COMPUTE MODULE - OUTPUTS
# ============================================================================

output "instance_id" {
  description = "ID da instância EC2"
  value       = aws_instance.wordpress.id
}

output "instance_arn" {
  description = "ARN da instância EC2"
  value       = aws_instance.wordpress.arn
}

output "private_ip" {
  description = "IP privado da instância EC2"
  value       = aws_instance.wordpress.private_ip
}

output "private_dns" {
  description = "DNS privado da instância EC2"
  value       = aws_instance.wordpress.private_dns
}

output "instance_state" {
  description = "Estado atual da instância"
  value       = aws_instance.wordpress.instance_state
}

output "iam_role_arn" {
  description = "ARN da IAM Role da EC2"
  value       = aws_iam_role.ec2_role.arn
}

output "iam_instance_profile_name" {
  description = "Nome do Instance Profile"
  value       = aws_iam_instance_profile.ec2_profile.name
}
