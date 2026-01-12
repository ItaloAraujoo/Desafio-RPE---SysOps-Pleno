# ============================================================================
# VARIÁVEIS GLOBAIS DO PROJETO
# ============================================================================

# ----------------------------------------------------------------------------
# Identificação
# ----------------------------------------------------------------------------

variable "project_name" {
  description = "Nome do projeto"
  type        = string
  default     = "wordpress-challenge"
}

variable "environment" {
  description = "Ambiente (dev, staging, prod)"
  type        = string
  default     = "dev"
}

# ----------------------------------------------------------------------------
# Região e Disponibilidade
# ----------------------------------------------------------------------------

variable "aws_region" {
  description = "Região AWS"
  type        = string
  default     = "us-east-1"
}

variable "availability_zones" {
  description = "Availability Zones"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

# ----------------------------------------------------------------------------
# Rede
# ----------------------------------------------------------------------------

variable "vpc_cidr_primary" {
  description = "CIDR principal da VPC"
  type        = string
  default     = "192.168.0.0/23"
}

variable "vpc_cidr_secondary" {
  description = "CIDR secundário da VPC"
  type        = string
  default     = "192.168.10.0/24"
}

variable "public_subnet_cidrs" {
  description = "CIDRs das subnets públicas"
  type        = list(string)
  default = [
    "192.168.0.0/28",
    "192.168.0.16/28"
  ]
}

variable "private_subnet_cidrs" {
  description = "CIDRs das subnets privadas"
  type        = list(string)
  default = [
    "192.168.0.128/25",
    "192.168.10.0/24"
  ]
}

# ----------------------------------------------------------------------------
# Segurança
# ----------------------------------------------------------------------------

variable "admin_ip" {
  description = "IP do administrador (CIDR)"
  type        = string
  default     = "0.0.0.0/0" # Alterar e colocar seu IP /32
}

variable "enable_flow_logs" {
  description = "Habilitar VPC Flow Logs"
  type        = bool
  default     = true
}

# ----------------------------------------------------------------------------
# Compute (EC2)
# ----------------------------------------------------------------------------

variable "instance_type" {
  description = "Tipo da instância EC2"
  type        = string
  default     = "t3.large"
}

variable "root_volume_size" {
  description = "Tamanho do volume root (GB)"
  type        = number
  default     = 30
}

variable "root_volume_type" {
  description = "Tipo do volume EBS"
  type        = string
  default     = "gp3"
}

# ----------------------------------------------------------------------------
# RDS
# ----------------------------------------------------------------------------

variable "enable_rds" {
  description = "Habilitar RDS MySQL"
  type        = bool
  default     = true
}

variable "rds_instance_class" {
  description = "Classe da instância RDS"
  type        = string
  default     = "db.t3.micro"
}

variable "rds_allocated_storage" {
  description = "Armazenamento RDS (GB)"
  type        = number
  default     = 20
}

variable "rds_multi_az" {
  description = "Habilitar Multi-AZ para RDS"
  type        = bool
  default     = false
}

# ----------------------------------------------------------------------------
# ALB
# ----------------------------------------------------------------------------

variable "enable_alb" {
  description = "Habilitar Application Load Balancer"
  type        = bool
  default     = true
}

# ----------------------------------------------------------------------------
# Alta Disponibilidade
# ----------------------------------------------------------------------------

variable "enable_multi_az_compute" {
  description = "Habilitar segunda EC2 em outra AZ"
  type        = bool
  default     = true
}

# ----------------------------------------------------------------------------
# Aplicação
# ----------------------------------------------------------------------------

variable "wordpress_port" {
  description = "Porta NodePort do WordPress"
  type        = number
  default     = 30000
}

variable "mysql_port" {
  description = "Porta do MySQL"
  type        = number
  default     = 3306
}

variable "container_runtime" {
  description = "Runtime de containers (k3s)"
  type        = string
  default     = "k3s"
}

# ----------------------------------------------------------------------------
# Tags
# ----------------------------------------------------------------------------

variable "additional_tags" {
  description = "Tags adicionais"
  type        = map(string)
  default     = {}
}
