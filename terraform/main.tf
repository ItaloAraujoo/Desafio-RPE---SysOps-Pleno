# ============================================================================
# MAIN TERRAFORM CONFIGURATION
# Orquestração dos módulos de infraestrutura
# ============================================================================

# ----------------------------------------------------------------------------
# DATA SOURCES
# ----------------------------------------------------------------------------

# Obtém a AMI mais recente do Amazon Linux 2023
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
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
# MODULE: VPC E NETWORKING
# ----------------------------------------------------------------------------

module "vpc" {
  source = "./modules/vpc/variables"

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
  source = "./modules/security/variables"

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
  source = "./modules/compute/variables"

  # Identificação
  project_name = var.project_name
  environment  = var.environment
  name_prefix  = local.name_prefix

  # Configuração de rede
  vpc_id            = module.vpc.vpc_id
  private_subnet_id = module.vpc.private_subnet_ids[0] # Subnet privada na AZ-1a
  security_group_id = module.security.private_sg_id

  # Configuração da instância
  ami_id           = data.aws_ami.amazon_linux_2023.id
  instance_type    = var.instance_type
  root_volume_size = var.root_volume_size
  root_volume_type = var.root_volume_type

  # User Data (script de inicialização)
  user_data = local.selected_user_data

  # Tags
  tags = local.common_tags

  depends_on = [module.vpc, module.security]
}

