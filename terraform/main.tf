# ============================================================================
# MAIN TERRAFORM CONFIGURATION
# Arquitetura: Multi-AZ com K3s, RDS e ALB
# ============================================================================

# ----------------------------------------------------------------------------
# DATA SOURCES
# ----------------------------------------------------------------------------

data "aws_ami" "ubuntu_22_04" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

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

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# ----------------------------------------------------------------------------
# RANDOM RESOURCES
# ----------------------------------------------------------------------------

resource "random_password" "mysql_root_password" {
  length           = 24
  special          = false
}

resource "random_password" "mysql_user_password" {
  length           = 20
  special          = false
}

resource "random_id" "suffix" {
  byte_length = 4
}

# ----------------------------------------------------------------------------
# LOCAL VALUES
# ----------------------------------------------------------------------------

locals {
  name_prefix = "${var.project_name}-${var.environment}"

  common_tags = merge(
    var.additional_tags,
    {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
      CreatedAt   = timestamp()
      AccountId   = data.aws_caller_identity.current.account_id
      Region      = data.aws_region.current.name
    }
  )

  # User data para K3s com RDS
  user_data_k3s = templatefile("${path.module}/templates/user_data_k3s.sh.tpl", {
    mysql_root_password = random_password.mysql_root_password.result
    mysql_user_password = random_password.mysql_user_password.result
    mysql_database      = "wordpress"
    mysql_user          = "wordpress"
    wordpress_port      = var.wordpress_port
    rds_endpoint        = var.enable_rds ? module.rds[0].address : "localhost"
  })
}

# ----------------------------------------------------------------------------
# MODULE: VPC
# ----------------------------------------------------------------------------

module "vpc" {
  source = "./modules/vpc"

  project_name = var.project_name
  environment  = var.environment
  name_prefix  = local.name_prefix

  vpc_cidr_primary     = var.vpc_cidr_primary
  vpc_cidr_secondary   = var.vpc_cidr_secondary
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  availability_zones   = var.availability_zones

  enable_flow_logs = var.enable_flow_logs

  tags = local.common_tags
}

# ----------------------------------------------------------------------------
# MODULE: SECURITY
# ----------------------------------------------------------------------------

module "security" {
  source = "./modules/security"

  project_name = var.project_name
  environment  = var.environment
  name_prefix  = local.name_prefix

  vpc_id   = module.vpc.vpc_id
  vpc_cidr = var.vpc_cidr_primary

  admin_ip       = var.admin_ip
  wordpress_port = var.wordpress_port
  mysql_port     = var.mysql_port

  tags = local.common_tags

  depends_on = [module.vpc]
}

# ----------------------------------------------------------------------------
# MODULE: RDS
# ----------------------------------------------------------------------------

module "rds" {
  count  = var.enable_rds ? 1 : 0
  source = "./modules/rds"

  project_name = var.project_name
  environment  = var.environment
  name_prefix  = local.name_prefix

  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  security_group_id  = module.security.rds_sg_id

  db_name           = "wordpress"
  db_username       = "admin"
  db_password       = random_password.mysql_root_password.result
  db_instance_class = var.rds_instance_class
  allocated_storage = var.rds_allocated_storage
  multi_az          = var.rds_multi_az

  tags = local.common_tags

  depends_on = [module.vpc, module.security]
}

# ----------------------------------------------------------------------------
# MODULE: ALB
# ----------------------------------------------------------------------------

module "alb" {
  count  = var.enable_alb ? 1 : 0
  source = "./modules/alb"

  name_prefix       = local.name_prefix
  vpc_id            = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids
  security_group_id = module.security.alb_sg_id
  target_port       = var.wordpress_port

  tags = local.common_tags

  depends_on = [module.vpc, module.security]
}

# ----------------------------------------------------------------------------
# MODULE: COMPUTE - EC2 AZ 1a
# ----------------------------------------------------------------------------

module "compute_1a" {
  source = "./modules/compute"

  project_name = var.project_name
  environment  = var.environment
  name_prefix  = "${local.name_prefix}-1a"

  vpc_id            = module.vpc.vpc_id
  private_subnet_id = module.vpc.private_subnet_ids[0]
  security_group_id = module.security.private_sg_id

  ami_id           = data.aws_ami.ubuntu_22_04.id
  instance_type    = var.instance_type
  root_volume_size = var.root_volume_size
  root_volume_type = var.root_volume_type

  user_data = local.user_data_k3s

  tags = merge(local.common_tags, {
    AZ   = var.availability_zones[0]
    Role = "K3s-WordPress"
  })

  depends_on = [module.vpc, module.security, module.rds]
}

# ----------------------------------------------------------------------------
# MODULE: COMPUTE - EC2 AZ 1b (Condicional)
# ----------------------------------------------------------------------------

module "compute_1b" {
  count  = var.enable_multi_az_compute ? 1 : 0
  source = "./modules/compute"

  project_name = var.project_name
  environment  = var.environment
  name_prefix  = "${local.name_prefix}-1b"

  vpc_id            = module.vpc.vpc_id
  private_subnet_id = module.vpc.private_subnet_ids[1]
  security_group_id = module.security.private_sg_id

  ami_id           = data.aws_ami.ubuntu_22_04.id
  instance_type    = var.instance_type
  root_volume_size = var.root_volume_size
  root_volume_type = var.root_volume_type

  user_data = local.user_data_k3s

  tags = merge(local.common_tags, {
    AZ   = var.availability_zones[1]
    Role = "K3s-WordPress"
  })

  depends_on = [module.vpc, module.security, module.rds]
}

# ----------------------------------------------------------------------------
# ALB TARGET GROUP ATTACHMENTS
# ----------------------------------------------------------------------------

resource "aws_lb_target_group_attachment" "wordpress_1a" {
  count            = var.enable_alb ? 1 : 0
  target_group_arn = module.alb[0].target_group_arn
  target_id        = module.compute_1a.instance_id
  port             = var.wordpress_port
}

resource "aws_lb_target_group_attachment" "wordpress_1b" {
  count            = var.enable_alb && var.enable_multi_az_compute ? 1 : 0
  target_group_arn = module.alb[0].target_group_arn
  target_id        = module.compute_1b[0].instance_id
  port             = var.wordpress_port
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
    username      = "admin"
    host          = var.enable_rds ? module.rds[0].address : "localhost"
  })
}
