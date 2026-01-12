# ============================================================================
# ALB MODULE - VARIABLES
# ============================================================================

variable "name_prefix" {
  description = "Prefixo para nomenclatura"
  type        = string
}

variable "vpc_id" {
  description = "ID da VPC"
  type        = string
}

variable "public_subnet_ids" {
  description = "IDs das subnets publicas para o ALB"
  type        = list(string)
}

variable "security_group_id" {
  description = "ID do Security Group do ALB"
  type        = string
}

variable "target_port" {
  description = "Porta do target (WordPress NodePort)"
  type        = number
  default     = 30000
}

variable "health_check_path" {
  description = "Path para health check"
  type        = string
  default     = "/wp-admin/install.php"
}

variable "tags" {
  description = "Tags"
  type        = map(string)
  default     = {}
}
