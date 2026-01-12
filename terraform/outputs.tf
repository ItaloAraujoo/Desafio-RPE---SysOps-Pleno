# ============================================================================
# TERRAFORM OUTPUTS
# ============================================================================

# ----------------------------------------------------------------------------
# VPC
# ----------------------------------------------------------------------------

output "vpc_id" {
  description = "ID da VPC"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "IDs das subnets públicas"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs das subnets privadas"
  value       = module.vpc.private_subnet_ids
}

# ----------------------------------------------------------------------------
# EC2 Instances
# ----------------------------------------------------------------------------

output "ec2_instance_1a" {
  description = "EC2 na AZ 1a"
  value = {
    instance_id = module.compute_1a.instance_id
    private_ip  = module.compute_1a.private_ip
    az          = var.availability_zones[0]
  }
}

output "ec2_instance_1b" {
  description = "EC2 na AZ 1b"
  value = var.enable_multi_az_compute ? {
    instance_id = module.compute_1b[0].instance_id
    private_ip  = module.compute_1b[0].private_ip
    az          = var.availability_zones[1]
  } : null
}

# ----------------------------------------------------------------------------
# RDS
# ----------------------------------------------------------------------------

output "rds_endpoint" {
  description = "Endpoint do RDS MySQL"
  value       = var.enable_rds ? module.rds[0].endpoint : null
}

output "rds_address" {
  description = "Hostname do RDS"
  value       = var.enable_rds ? module.rds[0].address : null
}

# ----------------------------------------------------------------------------
# ALB
# ----------------------------------------------------------------------------

output "alb_dns_name" {
  description = "DNS do ALB - Acesse o WordPress aqui!"
  value       = var.enable_alb ? module.alb[0].alb_dns_name : null
}

output "wordpress_url" {
  description = "URL do WordPress"
  value       = var.enable_alb ? "http://${module.alb[0].alb_dns_name}" : null
}

# ----------------------------------------------------------------------------
# SSM Commands
# ----------------------------------------------------------------------------

output "ssm_connect_1a" {
  description = "Comando para conectar na EC2 1a via SSM"
  value       = "aws ssm start-session --target ${module.compute_1a.instance_id}"
}

output "ssm_connect_1b" {
  description = "Comando para conectar na EC2 1b via SSM"
  value       = var.enable_multi_az_compute ? "aws ssm start-session --target ${module.compute_1b[0].instance_id}" : null
}

# ----------------------------------------------------------------------------
# Secrets
# ----------------------------------------------------------------------------

output "mysql_secret_name" {
  description = "Nome do secret com credenciais MySQL"
  value       = aws_secretsmanager_secret.mysql_credentials.name
}

# ----------------------------------------------------------------------------
# Resumo
# ----------------------------------------------------------------------------

output "project_summary" {
  description = "Resumo do projeto"
  value = {
    project          = var.project_name
    environment      = var.environment
    region           = data.aws_region.current.name
    runtime          = "K3s"
    rds_enabled      = var.enable_rds
    alb_enabled      = var.enable_alb
    multi_az_compute = var.enable_multi_az_compute
  }
}
