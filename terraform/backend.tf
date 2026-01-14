# =============================================================================
# TERRAFORM BACKEND CONFIGURATION (S3)
# =============================================================================
#
# IMPORTANTE: Antes de usar, você precisa criar o bucket S3 e a tabela DynamoDB.
# Execute o script setup-backend.sh para criar esses recursos.
#
# =============================================================================

terraform {
  backend "s3" {
    bucket         = "wordpress-challenge-terraform-state"
    key            = "wordpress/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "wordpress-challenge-terraform-locks"
  }
}

# =============================================================================
# Para usar backend local (desenvolvimento), comente o bloco acima e use:
# terraform init -backend=false
# =============================================================================
