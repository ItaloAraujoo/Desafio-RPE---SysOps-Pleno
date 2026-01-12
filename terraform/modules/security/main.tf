# ============================================================================
# SECURITY MODULE - MAIN
# ============================================================================

# ----------------------------------------------------------------------------
# SECURITY GROUP PÚBLICO
# Para recursos na subnet pública (NAT Gateway, ALB futuro)
# Acesso restrito ao IP do administrador
# ----------------------------------------------------------------------------

resource "aws_security_group" "public" {
  name        = "${var.name_prefix}-public-sg"
  description = "Security group para recursos publicos - Acesso restrito ao IP admin"
  vpc_id      = var.vpc_id

  # IMPORTANTE: Não há regras de ingress abertas para 0.0.0.0/0
  # Apenas o IP do administrador tem acesso

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-public-sg"
    Type = "Public"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# Regra de Ingress: SSH apenas do IP admin
resource "aws_vpc_security_group_ingress_rule" "public_ssh" {
  security_group_id = aws_security_group.public.id
  description       = "SSH from admin IP only"
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
  cidr_ipv4         = var.admin_ip

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-public-ssh-admin"
  })
}

# Regra de Ingress: HTTP apenas do IP admin
resource "aws_vpc_security_group_ingress_rule" "public_http" {
  security_group_id = aws_security_group.public.id
  description       = "HTTP from admin IP only"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  cidr_ipv4         = var.admin_ip

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-public-http-admin"
  })
}

# Regra de Ingress: HTTPS apenas do IP admin
resource "aws_vpc_security_group_ingress_rule" "public_https" {
  security_group_id = aws_security_group.public.id
  description       = "HTTPS from admin IP only"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  cidr_ipv4         = var.admin_ip

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-public-https-admin"
  })
}

# Regra de Egress: Permitir saída para Internet (necessário para NAT)
resource "aws_vpc_security_group_egress_rule" "public_all" {
  security_group_id = aws_security_group.public.id
  description       = "Allow all outbound traffic"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-public-egress-all"
  })
}

# ----------------------------------------------------------------------------
# SECURITY GROUP PRIVADO
# Para recursos na subnet privada (EC2 com containers)
# Aceita tráfego APENAS do SG público ou da própria VPC
# ----------------------------------------------------------------------------

resource "aws_security_group" "private" {
  name        = "${var.name_prefix}-private-sg"
  description = "Security group para recursos privados - Sem acesso direto da Internet"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-private-sg"
    Type = "Private"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# Regra de Ingress: SSH apenas do SG público (via Bastion)
resource "aws_vpc_security_group_ingress_rule" "private_ssh_from_public" {
  security_group_id            = aws_security_group.private.id
  description                  = "SSH from public security group (bastion)"
  from_port                    = 22
  to_port                      = 22
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.public.id

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-private-ssh-from-public"
  })
}

# Regra de Ingress: HTTP da VPC (para health checks internos)
resource "aws_vpc_security_group_ingress_rule" "private_http_from_vpc" {
  security_group_id = aws_security_group.private.id
  description       = "HTTP from VPC CIDR"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  cidr_ipv4         = var.vpc_cidr

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-private-http-from-vpc"
  })
}

# Regra de Ingress: WordPress port da VPC
resource "aws_vpc_security_group_ingress_rule" "private_wordpress_from_vpc" {
  security_group_id = aws_security_group.private.id
  description       = "WordPress port from VPC CIDR"
  from_port         = var.wordpress_port
  to_port           = var.wordpress_port
  ip_protocol       = "tcp"
  cidr_ipv4         = var.vpc_cidr

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-private-wordpress-from-vpc"
  })
}

# Regra de Ingress: WordPress port do SG público (para ALB futuro)
resource "aws_vpc_security_group_ingress_rule" "private_wordpress_from_public" {
  security_group_id            = aws_security_group.private.id
  description                  = "WordPress from public SG (ALB)"
  from_port                    = var.wordpress_port
  to_port                      = var.wordpress_port
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.public.id

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-private-wordpress-from-public"
  })
}

# Regra de Ingress: MySQL apenas interno (próprio SG)
resource "aws_vpc_security_group_ingress_rule" "private_mysql_internal" {
  security_group_id            = aws_security_group.private.id
  description                  = "MySQL internal communication"
  from_port                    = var.mysql_port
  to_port                      = var.mysql_port
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.private.id

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-private-mysql-internal"
  })
}

# Regra de Ingress: HTTPS para SSM Agent
resource "aws_vpc_security_group_ingress_rule" "private_https_ssm" {
  security_group_id = aws_security_group.private.id
  description       = "HTTPS for SSM Agent"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  cidr_ipv4         = var.vpc_cidr

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-private-https-ssm"
  })
}


# Regra de Egress: Saída para Internet via NAT (necessário para updates e downloads)
resource "aws_vpc_security_group_egress_rule" "private_all" {
  security_group_id = aws_security_group.private.id
  description       = "Allow all outbound traffic via NAT Gateway"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-private-egress-all"
  })
}

# ----------------------------------------------------------------------------
# NETWORK ACLs (Camada adicional de segurança)
# ----------------------------------------------------------------------------

# NACL para Subnets Públicas
resource "aws_network_acl" "public" {
  vpc_id = var.vpc_id

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-public-nacl"
  })
}

# NACL Rules - Ingress Públicas
resource "aws_network_acl_rule" "public_ingress_http" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 100
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 80
  to_port        = 80
}

resource "aws_network_acl_rule" "public_ingress_https" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 110
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 443
  to_port        = 443
}

resource "aws_network_acl_rule" "public_ingress_ssh" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 120
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = var.admin_ip
  from_port      = 22
  to_port        = 22
}

resource "aws_network_acl_rule" "public_ingress_ephemeral" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 200
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 1024
  to_port        = 65535
}

# NACL Rules - Egress Públicas
resource "aws_network_acl_rule" "public_egress_all" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 100
  egress         = true
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
}

# NACL para Subnets Privadas
resource "aws_network_acl" "private" {
  vpc_id = var.vpc_id

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-private-nacl"
  })
}

# NACL Rules - Ingress Privadas (apenas da VPC)
resource "aws_network_acl_rule" "private_ingress_vpc" {
  network_acl_id = aws_network_acl.private.id
  rule_number    = 100
  egress         = false
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = var.vpc_cidr
}

resource "aws_network_acl_rule" "private_ingress_ephemeral" {
  network_acl_id = aws_network_acl.private.id
  rule_number    = 200
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 1024
  to_port        = 65535
}

# NACL Rules - Egress Privadas
resource "aws_network_acl_rule" "private_egress_all" {
  network_acl_id = aws_network_acl.private.id
  rule_number    = 100
  egress         = true
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
}

# ----------------------------------------------------------------------------
# SECURITY GROUP PARA RDS
# ----------------------------------------------------------------------------

resource "aws_security_group" "rds" {
  name        = "${var.name_prefix}-rds-sg"
  description = "Security group para RDS MySQL"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-rds-sg"
    Type = "Database"
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "rds_mysql_from_private" {
  security_group_id            = aws_security_group.rds.id
  description                  = "MySQL from private instances"
  from_port                    = var.mysql_port
  to_port                      = var.mysql_port
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.private.id

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-rds-mysql-from-private"
  })
}

resource "aws_vpc_security_group_egress_rule" "rds_all" {
  security_group_id = aws_security_group.rds.id
  description       = "Allow all outbound"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-rds-egress-all"
  })
}

# ----------------------------------------------------------------------------
# SECURITY GROUP PARA ALB
# ----------------------------------------------------------------------------

resource "aws_security_group" "alb" {
  name        = "${var.name_prefix}-alb-sg"
  description = "Security group para Application Load Balancer"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-alb-sg"
    Type = "LoadBalancer"
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  security_group_id = aws_security_group.alb.id
  description       = "HTTP from anywhere"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  cidr_ipv4         = var.admin_ip  # Filtrado por IP autorizado

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-alb-http"
  })
}

resource "aws_vpc_security_group_ingress_rule" "alb_https" {
  security_group_id = aws_security_group.alb.id
  description       = "HTTPS from anywhere"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  cidr_ipv4         = var.admin_ip  # Filtrado por IP autorizado

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-alb-https"
  })
}

resource "aws_vpc_security_group_egress_rule" "alb_all" {
  security_group_id = aws_security_group.alb.id
  description       = "Allow all outbound"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-alb-egress-all"
  })
}

# Regra: Permitir tráfego do ALB para instâncias privadas
resource "aws_vpc_security_group_ingress_rule" "private_from_alb" {
  security_group_id            = aws_security_group.private.id
  description                  = "Traffic from ALB"
  from_port                    = var.wordpress_port
  to_port                      = var.wordpress_port
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.alb.id

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-private-from-alb"
  })
}
