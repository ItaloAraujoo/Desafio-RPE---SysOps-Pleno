# ============================================================================
# COMPUTE MODULE - VARIABLES
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

variable "private_subnet_id" {
  description = "ID da subnet privada onde a EC2 será criada"
  type        = string
}

variable "security_group_id" {
  description = "ID do Security Group para a EC2"
  type        = string
}

variable "ami_id" {
  description = "ID da AMI para a instância EC2"
  type        = string
}

variable "instance_type" {
  description = "Tipo da instância EC2"
  type        = string
  default     = "t3.medium"
}

variable "root_volume_size" {
  description = "Tamanho do volume root em GB"
  type        = number
  default     = 30
}

variable "root_volume_type" {
  description = "Tipo do volume EBS"
  type        = string
  default     = "gp3"
}

variable "user_data" {
  description = "Script de inicialização da instância"
  type        = string
}

variable "tags" {
  description = "Tags a serem aplicadas aos recursos"
  type        = map(string)
  default     = {}
}
