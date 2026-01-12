# ============================================================================
# COMPUTE MODULE - MAIN
# Provisionamento de EC2 na subnet privada com IAM Role para SSM
# ============================================================================

resource "aws_iam_role" "ec2_role" {
  name = "${var.name_prefix}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com" 
        }
      }
    ]
  })

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-ec2-role"
  })
}

# Política para SSM
resource "aws_iam_role_policy_attachment" "ssm_policy" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}


# Política para CloudWatch Logs (opcional - para logs de aplicação)
resource "aws_iam_role_policy_attachment" "cloudwatch_policy" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# Política para Secrets Manager (leitura de credenciais)
resource "aws_iam_role_policy" "secrets_manager" {
  name = "${var.name_prefix}-secrets-policy"
  role = aws_iam_role.ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Effect   = "Allow"
        Resource = "*"
        Condition = {
          StringEquals = {
            "secretsmanager:ResourceTag/Project" = var.project_name
          }
        }
      }
    ]
  })
}

# Instance Profile
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.name_prefix}-ec2-profile"
  role = aws_iam_role.ec2_role.name

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-ec2-profile"
  })
}

# ----------------------------------------------------------------------------
# EC2 INSTANCE
# Instância na subnet privada com K3S
# ----------------------------------------------------------------------------

resource "aws_instance" "wordpress" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = var.private_subnet_id
  vpc_security_group_ids = [var.security_group_id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name
  key_name               = "wordpress-key"


  # Configuração do volume root
  root_block_device {
    volume_size           = var.root_volume_size
    volume_type           = var.root_volume_type
    encrypted             = true
    delete_on_termination = true

    tags = merge(var.tags, {
      Name = "${var.name_prefix}-root-volume"
    })
  }

  # User Data para instalação automática
  user_data = base64encode(var.user_data)

  # Metadados da instância (IMDSv2 obrigatório)
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required" # IMDSv2
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }

  # Monitoramento detalhado
  monitoring = true

  # Desabilitar terminação acidental
  disable_api_termination = false 

  # Tags
  tags = merge(var.tags, {
    Name    = "${var.name_prefix}-wordpress-ec2"
    Type    = "Application"
    Runtime = "Docker"
  })

  lifecycle {
    ignore_changes = [
      ami, # Ignorar mudanças de AMI após criação
    ]
  }
}

# ----------------------------------------------------------------------------
# CLOUDWATCH ALARMS (Monitoramento básico)
# ----------------------------------------------------------------------------

resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "${var.name_prefix}-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "CPU utilization is over 80%"

  dimensions = {
    InstanceId = aws_instance.wordpress.id
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-cpu-alarm"
  })
}

resource "aws_cloudwatch_metric_alarm" "status_check" {
  alarm_name          = "${var.name_prefix}-status-check"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "StatusCheckFailed"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Maximum"
  threshold           = 0
  alarm_description   = "Instance status check failed"

  dimensions = {
    InstanceId = aws_instance.wordpress.id
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-status-alarm"
  })
}
