# Desafio-RPE---SysOps-Pleno
Este projeto implementa uma infraestrutura de rede na AWS, seguindo as melhores práticas de arquitetura Multi-AZ, com WordPress containerizado rodando em uma instância EC2 privada.

## Stack Tecnológica
- IAC: Terraform
- Cloud: AWS
- Orquestrador: K3S
- Banco de Dados: RDS
- SO: Ubuntu

## Estrutura do Projeto

```
terraform/
├── main.tf                      # Orquestração principal
├── variables.tf                 # Variáveis
├── outputs.tf                   # Outputs
├── providers.tf                 # Providers AWS
├── terraform.tfvars             # Valores
├── templates/
│   └── user_data_k3s.sh.tpl     # Script K3s
└── modules/
    ├── vpc/                     # VPC, Subnets, NAT
    ├── security/                # Security Groups, NACLs
    ├── compute/                 # EC2 Instances
    ├── rds/                     # RDS MySQL
    └── alb/                     # Load Balancer
