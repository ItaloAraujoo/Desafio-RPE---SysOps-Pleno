# ============================================================================
# TERRAFORM VARIABLES
# ============================================================================

# Identificação
project_name = "wordpress-challenge"
environment  = "dev"
aws_region   = "us-east-1"

# Rede
vpc_cidr_primary   = "192.168.0.0/23"
vpc_cidr_secondary = "192.168.10.0/24"

public_subnet_cidrs = [
  "192.168.0.0/28",
  "192.168.0.16/28"
]

private_subnet_cidrs = [
  "192.168.0.128/25",
  "192.168.10.0/24"
]

availability_zones = ["us-east-1a", "us-east-1b"]

# Segurança
admin_ip = "0.0.0.0/0"  # Altere para seu IP/32

# Compute
instance_type    = "t3.large"
root_volume_size = 30
root_volume_type = "gp3"

# RDS
enable_rds            = true
rds_instance_class    = "db.t3.micro"
rds_allocated_storage = 20
rds_multi_az          = true

# ALB
enable_alb = true

# Alta Disponibilidade
enable_multi_az_compute = true

# Aplicação
wordpress_port    = 30000
mysql_port        = 3306
container_runtime = "k3s"

# Monitoramento
enable_flow_logs = true

# Tags
additional_tags = {
  Owner   = "DevOps"
  Purpose = "WordPress Challenge - K3s"
  TestCICD = "true"
}
