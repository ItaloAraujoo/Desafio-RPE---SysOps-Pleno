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
```

##  Funcionalidades

- Multi-AZ: EC2s em duas Availability Zones
- K3s: Kubernetes (Orquestrador)
- RDS MySQL: Banco de dados gerenciado
- ALB: Load Balancer para HA
- VPC Endpoints: Acesso SSM privado
- Security Groups: Segurança em camadas
- Secrets Manager: Credenciais seguras
- Flow Logs: Para Auditoria de rede


## Deploy

### Pré-requisitos

- Terraform >= 1.6
- AWS CLI configurado
- Conta AWS com permissões

### Passos

```bash
# 1. Inicializar
cd terraform
terraform init

# 2. Planejar
terraform plan

# 3. Aplicar
terraform apply

# 4. Acessar WordPress
# Use o output alb_dns_name ou wordpress_url
```

##  Outputs

| `wordpress_url` | URL para acessar o WordPress |
| `alb_dns_name` | DNS do Load Balancer |
| `rds_endpoint` | Endpoint do banco de dados |
| `ssm_connect_1a` | Comando SSM para EC2 1a |
| `ssm_connect_1b` | Comando SSM para EC2 1b |


```hcl
# terraform.tfvars
enable_rds              = true   # RDS MySQL
enable_alb              = true   # Load Balancer
enable_multi_az_compute = true   # Segunda EC2
```


### Tipos de Instância

```hcl
instance_type      = "t3.large"    # EC2: 8GB RAM
rds_instance_class = "db.t3.micro" # RDS básico
```


## Segurança

- EC2s em subnets privadas
- RDS sem acesso público
- SSM para acesso às instâncias
- Security Groups restritivos
- Credenciais no Secrets Manager


##  Por que K3s?
O K3s resolve o problema de incompatibilidade entre o Kubernetes moderno e o Docker, empacotando tudo o que você precisa em um único arquivo.
O maior problema que enfrentamos foi o erro cri-dockerd.

No Minikube (Driver None): O Kubernetes moderno (1.24+) não fala mais nativamente com o Docker. Para eles conversarem, você precisa instalar um "tradutor" manual chamado cri-dockerd, além de plugins de rede (CNI) e configurar arquivos de sistema (systemd). Qualquer versão errada entre esses 4 componentes quebra tudo.

No K3s: Ele removeu o Docker da equação. O K3s já traz embutido o Containerd (que é o motor que roda containers hoje em dia). Ele não precisa de tradutor. Você instala o K3s e ele já tem o motor dentro dele funcionando.


## 📝 Limpeza do ambiente

```bash
terraform destroy
```
