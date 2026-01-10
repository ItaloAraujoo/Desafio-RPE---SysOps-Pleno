# ============================================================================
# VPC MODULE - VARIABLES
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

variable "vpc_cidr_primary" {
  description = "CIDR block principal da VPC"
  type        = string
}

variable "vpc_cidr_secondary" {
  description = "CIDR block secundário da VPC"
  type        = string
}

variable "public_subnet_cidrs" {
  description = "Lista de CIDRs para subnets públicas"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "Lista de CIDRs para subnets privadas"
  type        = list(string)
}

variable "availability_zones" {
  description = "Lista de Availability Zones"
  type        = list(string)
}

variable "enable_flow_logs" {
  description = "Habilitar VPC Flow Logs"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags a serem aplicadas aos recursos"
  type        = map(string)
  default     = {}
}