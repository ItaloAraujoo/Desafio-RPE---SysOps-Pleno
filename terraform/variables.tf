# ============================================================================
# VARIÁVEIS GLOBAIS DO PROJETO
# Definição de todas as variáveis utilizadas na infraestrutura
# ============================================================================

# ----------------------------------------------------------------------------
# Variáveis de Identificação do Projeto
# ----------------------------------------------------------------------------

variable "project_name" {
  description = "Nome do projeto, usado como prefixo para todos os recursos"
  type        = string
  default     = "wordpress-challenge"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{2,28}[a-z0-9]$", var.project_name))
    error_message = "O nome do projeto deve ter entre 4-30 caracteres, começar com letra, conter apenas letras minúsculas, números e hífens."
  }
}

variable "environment" {
  description = "Ambiente de deployment (dev, staging, prod)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "O ambiente deve ser: dev, staging ou prod."
  }
}

# ----------------------------------------------------------------------------
# Variáveis de Região e Disponibilidade
# ----------------------------------------------------------------------------

variable "aws_region" {
  description = "Região AWS para deployment"
  type        = string
  default     = "us-east-1"
}

variable "availability_zones" {
  description = "Lista de Availability Zones para Multi-AZ deployment"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]

  validation {
    condition     = length(var.availability_zones) >= 2
    error_message = "É necessário especificar pelo menos 2 Availability Zones para Multi-AZ."
  }
}

# ----------------------------------------------------------------------------
# Variáveis de Rede (CIDR Blocks)
# Baseado no planejamento de subnetting do desafio
# ----------------------------------------------------------------------------

variable "vpc_cidr_primary" {
  description = "CIDR block principal da VPC (bloco /23)"
  type        = string
  default     = "192.168.0.0/23"

  validation {
    condition     = can(cidrhost(var.vpc_cidr_primary, 0))
    error_message = "O CIDR da VPC primária deve ser um CIDR válido."
  }
}

variable "vpc_cidr_secondary" {
  description = "CIDR block secundário da VPC (bloco /24)"
  type        = string
  default     = "192.168.10.0/24"

  validation {
    condition     = can(cidrhost(var.vpc_cidr_secondary, 0))
    error_message = "O CIDR da VPC secundária deve ser um CIDR válido."
  }
}

variable "public_subnet_cidrs" {
  description = "CIDRs das subnets públicas (menor tamanho possível - /28)"
  type        = list(string)
  default = [
    "192.168.0.0/28",  # us-east-1a - 14 IPs úteis
    "192.168.0.16/28"  # us-east-1b - 14 IPs úteis
  ]
}

variable "private_subnet_cidrs" {
  description = "CIDRs das subnets privadas (restante do espaço para aplicações)"
  type        = list(string)
  default = [
    "192.168.0.128/25", # us-east-1a - 126 IPs úteis
    "192.168.10.0/24"   # us-east-1b - 254 IPs úteis (bloco secundário completo)
  ]
}

# ----------------------------------------------------------------------------
# Variáveis de Segurança
# ----------------------------------------------------------------------------

variable "admin_ip" {
  description = "IP do administrador autorizado a acessar recursos (CIDR notation)"
  type        = string
  default     = "203.0.113.10/32" # IP fictício - ALTERAR para seu IP real

  validation {
    condition     = can(cidrhost(var.admin_ip, 0))
    error_message = "O IP do administrador deve estar em formato CIDR (ex: 203.0.113.10/32)."
  }
}

variable "enable_flow_logs" {
  description = "Habilitar VPC Flow Logs para auditoria de tráfego"
  type        = bool
  default     = true
}

# ----------------------------------------------------------------------------
# Variáveis de Compute (EC2)
# ----------------------------------------------------------------------------

variable "instance_type" {
  description = "Tipo da instância EC2 (t3.medium recomendado para Minikube)"
  type        = string
  default     = "t3.medium"

  validation {
    condition     = can(regex("^t[23]\\.(micro|small|medium|large|xlarge|2xlarge)$", var.instance_type))
    error_message = "O tipo de instância deve ser da família t2 ou t3."
  }
}

variable "root_volume_size" {
  description = "Tamanho do volume root da EC2 em GB"
  type        = number
  default     = 30

  validation {
    condition     = var.root_volume_size >= 20 && var.root_volume_size <= 100
    error_message = "O tamanho do volume deve estar entre 20 e 100 GB."
  }
}

variable "root_volume_type" {
  description = "Tipo do volume EBS (gp3 recomendado)"
  type        = string
  default     = "gp3"
}

# ----------------------------------------------------------------------------
# Variáveis de Aplicação (WordPress/MySQL)
# ----------------------------------------------------------------------------

variable "wordpress_port" {
  description = "Porta exposta pelo WordPress"
  type        = number
  default     = 30000
}

variable "mysql_port" {
  description = "Porta do MySQL"
  type        = number
  default     = 3306
}

variable "container_runtime" {
  description = "Runtime de containers a ser instalado (minikube)"
  type        = string
  default     = "minikube"

  validation {
    condition     = contains(["minikube"], var.container_runtime)
    error_message = "O runtime deve ser: minikube."
  }
}

# ----------------------------------------------------------------------------
# Tags Adicionais
# ----------------------------------------------------------------------------

variable "additional_tags" {
  description = "Tags adicionais para aplicar em todos os recursos"
  type        = map(string)
  default     = {}
}
