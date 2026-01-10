# ============================================================================
# VPC MODULE - OUTPUTS
# ============================================================================

output "vpc_id" {
  description = "ID da VPC"
  value       = aws_vpc.main.id
}

output "vpc_arn" {
  description = "ARN da VPC"
  value       = aws_vpc.main.arn
}

output "vpc_cidr_block" {
  description = "CIDR block principal da VPC"
  value       = aws_vpc.main.cidr_block
}

output "internet_gateway_id" {
  description = "ID do Internet Gateway"
  value       = aws_internet_gateway.main.id
}

output "nat_gateway_id" {
  description = "ID do NAT Gateway"
  value       = aws_nat_gateway.main.id
}

output "nat_gateway_public_ip" {
  description = "IP público do NAT Gateway"
  value       = aws_eip.nat.public_ip
}

output "public_subnet_ids" {
  description = "IDs das subnets públicas"
  value       = aws_subnet.public[*].id
}

output "public_subnet_cidrs" {
  description = "CIDRs das subnets públicas"
  value       = aws_subnet.public[*].cidr_block
}

output "private_subnet_ids" {
  description = "IDs das subnets privadas"
  value       = aws_subnet.private[*].id
}

output "private_subnet_cidrs" {
  description = "CIDRs das subnets privadas"
  value       = aws_subnet.private[*].cidr_block
}

output "public_route_table_id" {
  description = "ID da Route Table pública"
  value       = aws_route_table.public.id
}

output "private_route_table_id" {
  description = "ID da Route Table privada"
  value       = aws_route_table.private.id
}

output "flow_logs_group_name" {
  description = "Nome do CloudWatch Log Group para Flow Logs"
  value       = var.enable_flow_logs ? aws_cloudwatch_log_group.flow_logs[0].name : ""
}

output "vpc_endpoints_security_group_id" {
  description = "ID do Security Group dos VPC Endpoints"
  value       = aws_security_group.vpc_endpoints.id
}
