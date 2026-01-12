# ============================================================================
# RDS MODULE - MAIN
# MySQL gerenciado para WordPress
# ============================================================================

# ----------------------------------------------------------------------------
# DB SUBNET GROUP
# ----------------------------------------------------------------------------

resource "aws_db_subnet_group" "main" {
  name        = "${var.name_prefix}-db-subnet-group"
  description = "Subnet group para RDS MySQL"
  subnet_ids  = var.private_subnet_ids

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-db-subnet-group"
  })
}

# ----------------------------------------------------------------------------
# RDS MYSQL INSTANCE
# ----------------------------------------------------------------------------

resource "aws_db_instance" "wordpress" {
  identifier = "${var.name_prefix}-mysql"

  # Engine
  engine               = "mysql"
  engine_version       = "8.0"
  parameter_group_name = "default.mysql8.0"

  # Sizing
  instance_class    = var.db_instance_class
  allocated_storage = var.allocated_storage
  storage_type      = "gp3"
  storage_encrypted = true

  # Database
  db_name  = var.db_name
  username = var.db_username
  password = var.db_password
  port     = 3306

  # Network
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [var.security_group_id]
  publicly_accessible    = false

  # High Availability
  multi_az = var.multi_az

  # Backup
  backup_retention_period = 7
  backup_window           = "03:00-04:00"
  maintenance_window      = "Mon:04:00-Mon:05:00"

  # Snapshots
  skip_final_snapshot       = true
  final_snapshot_identifier = "${var.name_prefix}-final-snapshot"
  delete_automated_backups  = true

  # Protection
  deletion_protection = false

  # Performance
  performance_insights_enabled = false

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-mysql"
  })
}
