#!/bin/bash
# =============================================================================
# Este script cria os recursos necessários para o backend remoto do Terraform:
# - Bucket S3 (armazenar estado)
# - Tabela DynamoDB (state locking)
# =============================================================================

set -e

# Configurações
BUCKET_NAME="wordpress-challenge-terraform-state"
DYNAMODB_TABLE="wordpress-challenge-terraform-locks"
REGION="us-east-1"

echo "=========================================="
echo "Setup Terraform Backend"
echo "=========================================="
echo ""
echo "Bucket S3: $BUCKET_NAME"
echo "DynamoDB Table: $DYNAMODB_TABLE"
echo "Region: $REGION"
echo ""

# -----------------------------------------------------------------------------
# Verificar AWS CLI
# -----------------------------------------------------------------------------
if ! command -v aws &> /dev/null; then
    echo "AWS CLI não encontrado. Instale e configure primeiro."
    exit 1
fi

# Verificar credenciais
echo "Verificando credenciais AWS..."
aws sts get-caller-identity > /dev/null 2>&1 || {
    echo "Credenciais AWS não configuradas. Execute 'aws configure' primeiro."
    exit 1
}
echo "Credenciais OK"
echo ""

# -----------------------------------------------------------------------------
# Criar Bucket S3
# -----------------------------------------------------------------------------
echo "Criando bucket S3..."

if aws s3api head-bucket --bucket "$BUCKET_NAME" 2>/dev/null; then
    echo "Bucket já existe: $BUCKET_NAME"
else
    # Criar bucket
    if [ "$REGION" = "us-east-1" ]; then
        aws s3api create-bucket \
            --bucket "$BUCKET_NAME" \
            --region "$REGION"
    else
        aws s3api create-bucket \
            --bucket "$BUCKET_NAME" \
            --region "$REGION" \
            --create-bucket-configuration LocationConstraint="$REGION"
    fi
    echo "Bucket criado: $BUCKET_NAME"
fi

# Habilitar versionamento
echo "Habilitando versionamento..."
aws s3api put-bucket-versioning \
    --bucket "$BUCKET_NAME" \
    --versioning-configuration Status=Enabled
echo "Versionamento habilitado"

# Habilitar encryption
echo "Habilitando encryption..."
aws s3api put-bucket-encryption \
    --bucket "$BUCKET_NAME" \
    --server-side-encryption-configuration '{
        "Rules": [{
            "ApplyServerSideEncryptionByDefault": {
                "SSEAlgorithm": "AES256"
            }
        }]
    }'
echo "Encryption habilitada"

# Bloquear acesso público
echo "Bloqueando acesso público..."
aws s3api put-public-access-block \
    --bucket "$BUCKET_NAME" \
    --public-access-block-configuration '{
        "BlockPublicAcls": true,
        "IgnorePublicAcls": true,
        "BlockPublicPolicy": true,
        "RestrictPublicBuckets": true
    }'
echo "Acesso público bloqueado"

# Adicionar tags
echo "Adicionando tags..."
aws s3api put-bucket-tagging \
    --bucket "$BUCKET_NAME" \
    --tagging '{
        "TagSet": [
            {"Key": "Project", "Value": "wordpress-challenge"},
            {"Key": "Purpose", "Value": "Terraform State"},
            {"Key": "ManagedBy", "Value": "Terraform"}
        ]
    }'
echo "Tags adicionadas"

echo ""

# -----------------------------------------------------------------------------
# Criar Tabela DynamoDB
# -----------------------------------------------------------------------------
echo "Criando tabela DynamoDB..."

if aws dynamodb describe-table --table-name "$DYNAMODB_TABLE" --region "$REGION" 2>/dev/null; then
    echo "Tabela já existe: $DYNAMODB_TABLE"
else
    aws dynamodb create-table \
        --table-name "$DYNAMODB_TABLE" \
        --attribute-definitions AttributeName=LockID,AttributeType=S \
        --key-schema AttributeName=LockID,KeyType=HASH \
        --billing-mode PAY_PER_REQUEST \
        --region "$REGION" \
        --tags \
            Key=Project,Value=wordpress-challenge \
            Key=Purpose,Value="Terraform State Locking" \
            Key=ManagedBy,Value=Terraform
    
    echo "Aguardando tabela ficar ativa..."
    aws dynamodb wait table-exists --table-name "$DYNAMODB_TABLE" --region "$REGION"
    echo "Tabela criada: $DYNAMODB_TABLE"
fi

echo ""
echo "=========================================="
echo "Backend configurado com sucesso!"
echo "=========================================="
echo ""
echo "Próximos passos:"
echo ""
echo "1. Descomente o bloco backend em terraform/backend.tf"
echo ""
echo "2. Inicialize o Terraform com o novo backend:"
echo "   cd terraform"
echo "   terraform init"
echo ""
echo "3. Se já tiver estado local, migre com:"
echo "   terraform init -migrate-state"
echo ""
echo "=========================================="
