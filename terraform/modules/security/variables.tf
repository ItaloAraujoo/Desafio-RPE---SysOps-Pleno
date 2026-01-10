# ============================================================================
# SECURITY MODULE - VARIABLES
# ============================================================================

variable "project_name" {
  description = "Nome do projeto"
  type        = string
}

variable "environment" {
  description = "Ambiente (dev, staging, prod)"
  type        = string
}

variable "name_prefix" {
  description = "Prefixo para nomenclatura dos recursos"
  type        = string
}

variable "vpc_id" {
  description = "ID da VPC"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block da VPC"
  type        = string
}

variable "admin_ip" {
  description = "IP do administrador autorizado (CIDR notation)"
  type        = string
}

variable "wordpress_port" {
  description = "Porta do WordPress"
  type        = number
  default     = 8080
}

variable "mysql_port" {
  description = "Porta do MySQL"
  type        = number
  default     = 3306
}

variable "tags" {
  description = "Tags a serem aplicadas aos recursos"
  type        = map(string)
  default     = {}
}
