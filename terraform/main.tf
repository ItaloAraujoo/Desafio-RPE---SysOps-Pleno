# ============================================================================
# MAIN TERRAFORM CONFIGURATION
# Orquestração dos módulos de infraestrutura
# ============================================================================

# ----------------------------------------------------------------------------
# DATA SOURCES
# ----------------------------------------------------------------------------

# Obtém a AMI mais recente do Amazon Linux 2023
data "aws_ami" "ubuntu_22_04" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

# Obtém informações da conta AWS atual
data "aws_caller_identity" "current" {}

# Obtém informações da região atual
data "aws_region" "current" {}

# ----------------------------------------------------------------------------
# RANDOM RESOURCES
# Geração de strings aleatórias para senhas e identificadores únicos
# ----------------------------------------------------------------------------

# Senha do banco de dados MySQL
resource "random_password" "mysql_root_password" {
  length           = 24
  special          = true
  override_special = "!#$%&*()-_=+[]{}|"
}

resource "random_password" "mysql_user_password" {
  length           = 20
  special          = true
  override_special = "!#$%&*()-_=+[]{}|"
}

# Sufixo único para recursos que precisam de nomes globalmente únicos
resource "random_id" "suffix" {
  byte_length = 4
}

# ----------------------------------------------------------------------------
# LOCAL VALUES
# Valores computados utilizados em múltiplos módulos
# ----------------------------------------------------------------------------

locals {
  # Nome base com sufixo único
  name_prefix = "${var.project_name}-${var.environment}"

  # Tags comuns aplicadas a todos os recursos
  common_tags = merge(
    var.additional_tags,
    {
      Project       = var.project_name
      Environment   = var.environment
      ManagedBy     = "Terraform"
      CreatedAt     = timestamp()
      AccountId     = data.aws_caller_identity.current.account_id
      Region        = data.aws_region.current.name
    }
  )

  #Configuração do user_data
  user_data_minikube = templatefile("${path.module}/templates/user_data_minikube.sh.tpl", {
    mysql_root_password = random_password.mysql_root_password.result
    mysql_user_password = random_password.mysql_user_password.result
    mysql_database      = "wordpress"
    mysql_user          = "wordpress"
    wordpress_port      = var.wordpress_port
    CNI_PLUGIN_VERSION  = "v1.3.0"
    CRICTL_VERSION      = "v1.31.1"
    CRI_DOCKERD_VERSION = "0.3.4"
  })

  # Seleciona o user_data apropriado baseado na variável
  selected_user_data = var.container_runtime == "minikube" ? local.user_data_minikube : null
}

# ----------------------------------------------------------------------------
# MODULE: VPC E NETWORKING
# ----------------------------------------------------------------------------

module "vpc" {
  source = "./modules/vpc"

  # Identificação
  project_name = var.project_name
  environment  = var.environment
  name_prefix  = local.name_prefix

  # Configuração de rede
  vpc_cidr_primary     = var.vpc_cidr_primary
  vpc_cidr_secondary   = var.vpc_cidr_secondary
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  availability_zones   = var.availability_zones

  # Flow Logs
  enable_flow_logs = var.enable_flow_logs

  # Tags
  tags = local.common_tags
}

# ----------------------------------------------------------------------------
# MODULE: SECURITY GROUPS
# ----------------------------------------------------------------------------

module "security" {
  source = "./modules/security"

  # Identificação
  project_name = var.project_name
  environment  = var.environment
  name_prefix  = local.name_prefix

  # Dependências de rede
  vpc_id   = module.vpc.vpc_id
  vpc_cidr = var.vpc_cidr_primary

  # Configuração de segurança
  admin_ip       = var.admin_ip
  wordpress_port = var.wordpress_port
  mysql_port     = var.mysql_port

  # Tags
  tags = local.common_tags

  depends_on = [module.vpc]
}

# ----------------------------------------------------------------------------
# MODULE: COMPUTE (EC2)
# ----------------------------------------------------------------------------

module "compute" {
  source = "./modules/compute"

  # Identificação
  project_name = var.project_name
  environment  = var.environment
  name_prefix  = local.name_prefix

  # Configuração de rede
  vpc_id            = module.vpc.vpc_id
  private_subnet_id = module.vpc.private_subnet_ids[0] # Subnet privada na AZ-1a
  security_group_id = module.security.private_sg_id

  # Configuração da instância
  ami_id           = data.aws_ami.ubuntu_22_04.id
  instance_type    = var.instance_type
  root_volume_size = var.root_volume_size
  root_volume_type = var.root_volume_type

  # User Data (script de inicialização)
  user_data = local.selected_user_data

  # Tags
  tags = local.common_tags

  depends_on = [module.vpc, module.security]
}

# ----------------------------------------------------------------------------
# SECRETS MANAGER
# ----------------------------------------------------------------------------

resource "aws_secretsmanager_secret" "mysql_credentials" {
  name                    = "${local.name_prefix}-mysql-credentials-${random_id.suffix.hex}"
  description             = "Credenciais do MySQL para WordPress"
  recovery_window_in_days = 7

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-mysql-credentials"
  })
}

resource "aws_secretsmanager_secret_version" "mysql_credentials" {
  secret_id = aws_secretsmanager_secret.mysql_credentials.id
  secret_string = jsonencode({
    root_password = random_password.mysql_root_password.result
    user_password = random_password.mysql_user_password.result
    database      = "wordpress"
    username      = "wordpress"
  })
}
