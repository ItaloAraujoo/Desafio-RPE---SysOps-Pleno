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

  # Descomente para usar backend remoto (recomendado para produção)
  # backend "s3" {
  #   bucket         = "seu-bucket-terraform-state"
  #   key            = "wordpress-challenge/terraform.tfstate"
  #   region         = "us-east-1"
  #   encrypt        = true
  #   dynamodb_table = "terraform-locks"
  # }
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
