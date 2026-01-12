# Desafio-RPE---SysOps-Pleno
Este projeto provisiona uma infraestrutura completa, segura e escalável para hospedar um WordPress utilizando Kubernetes (K3s) sobre instâncias EC2 e banco de dados gerenciado Amazon RDS. Todo o provisionamento é realizado via Terraform (IaC).

## Topologia de Rede
<img width="526" height="557" alt="image" src="https://github.com/user-attachments/assets/b685b12e-616a-427d-ba95-d37ac77ebcfe" />


## Decisões Técnicas e Arquitetura

A rede foi desenhada para isolar componentes públicos de privados, seguindo as melhores práticas de segurança da AWS.

Subnets Públicas (us-east-1a/b): Hospedam apenas o Application Load Balancer (ALB) e NAT Gateways. Nenhuma aplicação ou banco de dados reside aqui.

Subnets Privadas (us-east-1a/b): Hospedam as instâncias EC2 (App) e o RDS (Dados). Elas não possuem IP público e acessam a internet apenas via NAT Gateway para atualizações.

Escolha dos Tamanhos de Subnet (CIDR)

A alocação de IPs foi planejada para eficiência e economia de endereços:

- Public A: Pequena. Apenas para infraestrutura de borda (ALB/NAT) que consome poucos IPs. | CIDR: /28 | Qtd IPs: 16  | 192.168.0.0/28
- Public B: Pequena. Para ALB (Alta disponibilidade). | CIDR: /28 | Qtd IPs: 16 | 192.168.0.16/28
- Private A: Média. Espaço suficiente para Autoscaling de nós EC2 e Pods Kubernetes.     | CIDR: /25 | Qtd IPs: 128 | 192.168.0.128/25
- Private B: Grande. Reserva para expansão futura ou serviços de dados adicionais.       | CIDR: /24 | Qtd IPs: 256 | 192.168.10.0/24

Persistência de Dados e Alta Disponibilidade (HA)
A estratégia de persistência foi desacoplada para garantir que a perda de uma instância EC2 não resulte em perda de dados.

Banco de Dados (RDS Multi-AZ):
O MySQL roda fora do cluster Kubernetes, no Amazon RDS.

Multi-AZ Habilitado: Existe uma réplica "sombra" (Standby) em uma segunda zona de disponibilidade. Se a zona primária falhar, a AWS chaveia o DNS automaticamente para a réplica.

Mecanismos de Segurança
Security Groups (Firewall Stateful):

ALB: Aceita apenas HTTP/HTTPS (80/443) de 0.0.0.0/0.

EC2: Aceita tráfego apenas vindo do Security Group do ALB. Ninguém acessa a EC2 direto da internet.

RDS: Aceita conexão apenas na porta 3306 vinda do Security Group da EC2.

IAM & SSM:
SSH (Porta 22) não é exposto. O acesso administrativo é feito via AWS Systems Manager (Session Manager), garantindo auditabilidade e eliminando a gestão de chaves

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
### Tipos de Instância

```hcl
instance_type      = "t3.large"    # EC2: 8GB RAM
rds_instance_class = "db.t3.micro" # RDS básico
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

## Segurança

- EC2s em subnets privadas
- RDS sem acesso público
- SSM para acesso às instâncias
- Security Groups restritivos
- Credenciais no Secrets Manager

## Como Subir o Ambiente (Passo a Passo)

OBS:
O deploy é automatizado via user_data que realiza:
- Instalação do K3s.
- Aplicação dos manifestos Kubernetes (Deployment, Service, Secret, ConfigMap).
- As credenciais do banco não são hardcoded no código; elas são injetadas pelo Terraform durante a criação do template.

### Pré-requisitos

- Terraform >= 1.6
- AWS CLI configurado: exemplo de configuração abaixo.
- AWS - UBUNTU
- curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
- unzip awscliv2.zip
- sudo ./aws/install
- aws configure
- Necessário ter Access key ID e Secret access key
  
- Conta AWS com permissões

1. Clone o Repositório
- git clone url-repositorio

2. Configure as Variáveis
- Edite o arquivo terraform.tfvars:

3. Inicialize e Aplique

```bash
cd terraform (necessário estar no diretorio /terraform para aplicar os comandos abaixo)

# Inicializar
- terraform init

# Validar configuração
- terraform validate

# Planejar
- terraform plan

# Aplicar
- terraform apply

# 4. Acessar WordPress
# Use o output alb_dns_name ou wordpress_url
```

4. Aguardar o Bootstrapping
Após o Terraform finalizar, a instância EC2 executará o script user_data para instalar o K3s e subir os Pods.

Tempo estimado: 4 a 6 minutos após a criação da EC2.

## Como Testar o Ambiente

Acesso Público (Usuário Final)
Obtenha o DNS do Load Balancer gerado pelo Terraform:
- terraform output alb_dns_name

Acesse esse endereço no navegador. Você deverá ver a tela de instalação do WordPress.

Para verificar se os Pods estão rodando, conecte-se à instância via SSM (pelo Console AWS ou CLI):
- aws ssm start-session --target <INSTANCE_ID>

Verificar status do cluster: 
- sudo kubectl get pods -n wordpress
- sudo kubectl get svc -n wordpress

# Ver eventos do cluster
- sudo kubectl get events -n wordpress

# Verificar logs do WordPress
- sudo kubectl logs -n wordpress -l app=wordpress


## 📝 Limpeza do ambiente

```bash
terraform destroy
```


##  Por que K3s?
O K3s resolve o problema de incompatibilidade entre o Kubernetes moderno e o Docker, empacotando tudo o que você precisa em um único arquivo.
O maior problema enfrentado foi o erro cri-dockerd usando o minikube.

No Minikube (Driver None): O Kubernetes moderno (1.24+) não fala mais nativamente com o Docker. Para eles conversarem, você precisa instalar um "tradutor" manual chamado cri-dockerd, além de plugins de rede (CNI) e configurar arquivos de sistema (systemd). Qualquer versão errada entre esses 4 componentes quebra tudo.

No K3s: Ele removeu o Docker da equação. O K3s já traz embutido o Containerd (que é o motor que roda containers hoje em dia). Ele não precisa de tradutor. Você instala o K3s e ele já tem o motor dentro dele funcionando.


## Próximos passos
CI/CD para aplicar IaC automaticamente
