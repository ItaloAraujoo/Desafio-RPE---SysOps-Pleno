# ============================================================================
# PROVIDERS CONFIGURATION
# AWS Provider e configurações de versão do Terraform
# ============================================================================

terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}

# ============================================================================
# AWS PROVIDER
# ============================================================================

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
      Owner       = "SysOps-Challenge"
    }
  }
}

# ============================================================================
# RANDOM PROVIDER
# Usado para gerar strings aleatórias para senhas e sufixos únicos
# ============================================================================

provider "random" {}
