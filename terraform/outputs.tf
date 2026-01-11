# ============================================================================
# TERRAFORM OUTPUTS
# Informações importantes expostas após o deploy
# ============================================================================

# ----------------------------------------------------------------------------
# VPC OUTPUTS
# ----------------------------------------------------------------------------

output "vpc_id" {
  description = "ID da VPC criada"
  value       = module.vpc.vpc_id
}

output "vpc_cidr_blocks" {
  description = "Blocos CIDR da VPC"
  value = {
    primary   = var.vpc_cidr_primary
    secondary = var.vpc_cidr_secondary
  }
}

output "internet_gateway_id" {
  description = "ID do Internet Gateway"
  value       = module.vpc.internet_gateway_id
}

output "nat_gateway_id" {
  description = "ID do NAT Gateway"
  value       = module.vpc.nat_gateway_id
}

output "nat_gateway_public_ip" {
  description = "IP público do NAT Gateway"
  value       = module.vpc.nat_gateway_public_ip
}

# ----------------------------------------------------------------------------
# SUBNET OUTPUTS
# ----------------------------------------------------------------------------

output "public_subnet_ids" {
  description = "IDs das subnets públicas"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs das subnets privadas"
  value       = module.vpc.private_subnet_ids
}

output "subnet_details" {
  description = "Detalhes completos das subnets"
  value = {
    public = [
      for idx, cidr in var.public_subnet_cidrs : {
        cidr = cidr
        az   = var.availability_zones[idx]
        type = "public"
      }
    ]
    private = [
      for idx, cidr in var.private_subnet_cidrs : {
        cidr = cidr
        az   = var.availability_zones[idx]
        type = "private"
      }
    ]
  }
}

# ----------------------------------------------------------------------------
# SECURITY GROUP OUTPUTS
# ----------------------------------------------------------------------------

output "public_security_group_id" {
  description = "ID do Security Group público"
  value       = module.security.public_sg_id
}

output "private_security_group_id" {
  description = "ID do Security Group privado"
  value       = module.security.private_sg_id
}

# ----------------------------------------------------------------------------
# EC2 OUTPUTS
# ----------------------------------------------------------------------------

output "ec2_instance_id" {
  description = "ID da instância EC2"
  value       = module.compute.instance_id
}

output "ec2_private_ip" {
  description = "IP privado da instância EC2"
  value       = module.compute.private_ip
}

output "ec2_instance_state" {
  description = "Estado atual da instância EC2"
  value       = module.compute.instance_state
}

# ----------------------------------------------------------------------------
# SSM CONNECTION
# ----------------------------------------------------------------------------

output "ssm_connection_command" {
  description = "Comando para conectar via AWS SSM Session Manager"
  value       = "aws ssm start-session --target ${module.compute.instance_id}"
}

output "ssm_port_forward_command" {
  description = "Comando para port-forward do WordPress via SSM"
  value       = "aws ssm start-session --target ${module.compute.instance_id} --document-name AWS-StartPortForwardingSession --parameters '{\"portNumber\":[\"${var.wordpress_port}\"],\"localPortNumber\":[\"8080\"]}'"
}

# ----------------------------------------------------------------------------
# SECRETS MANAGER OUTPUT
# ----------------------------------------------------------------------------

output "mysql_credentials_secret_arn" {
  description = "ARN do secret com credenciais MySQL no Secrets Manager"
  value       = aws_secretsmanager_secret.mysql_credentials.arn
  sensitive   = true
}

output "mysql_credentials_secret_name" {
  description = "Nome do secret com credenciais MySQL"
  value       = aws_secretsmanager_secret.mysql_credentials.name
}

# ----------------------------------------------------------------------------
# INFORMAÇÕES DO PROJETO
# ----------------------------------------------------------------------------

output "project_info" {
  description = "Informações gerais do projeto"
  value = {
    project_name      = var.project_name
    environment       = var.environment
    region            = data.aws_region.current.name
    account_id        = data.aws_caller_identity.current.account_id
    container_runtime = var.container_runtime
    admin_ip          = var.admin_ip
  }
}

# ----------------------------------------------------------------------------
# FLOW LOGS OUTPUT (condicional)
# ----------------------------------------------------------------------------

output "flow_logs_group_name" {
  description = "Nome do CloudWatch Log Group para VPC Flow Logs"
  value       = var.enable_flow_logs ? module.vpc.flow_logs_group_name : "Flow Logs desabilitado"
}
