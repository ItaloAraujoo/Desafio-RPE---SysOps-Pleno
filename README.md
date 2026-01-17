# Desafio - SysOps-Pleno-RPE
Este projeto provisiona uma infraestrutura completa, segura e escalável para hospedar um WordPress utilizando Kubernetes (K3s) sobre instâncias EC2 e banco de dados gerenciado Amazon RDS. Todo o provisionamento é realizado via Terraform (IaC).

## Arquitetura Cloud AWS
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

##  Por que K3s?
O K3s resolve o problema de incompatibilidade entre o Kubernetes moderno e o Docker, empacotando tudo o que você precisa em um único arquivo.
O maior problema enfrentado foi o erro cri-dockerd usando o minikube.

No Minikube (Driver None): O Kubernetes moderno (1.24+) não fala mais nativamente com o Docker. Para eles conversarem, você precisa instalar um "tradutor" manual chamado cri-dockerd, além de plugins de rede (CNI) e configurar arquivos de sistema (systemd). Qualquer versão errada entre esses 4 componentes quebra tudo.

No K3s: Ele removeu o Docker da equação. O K3s já traz embutido o Containerd (que é o motor que roda containers hoje em dia). Ele não precisa de tradutor. Você instala o K3s e ele já tem o motor dentro dele funcionando.


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

### Acesso a aplicação:
exemplo: aws ssm start-session --target i-0058e16b5e6dec22f --document-name AWS-StartPortForwardingSession --parameters '{"portNumber":["30000"],"localPortNumber":["8080"]}'

Esse comando cria um túnel SSH/port forwarding do seu local para a instância.

Encaminha uma porta específica da instância para seu computador local.

- logo após isso digite no navegador: http:localhost:8080

### Acesso via DNS:
- comando para pegar url: terraform output wordpress_url
- O acesso é filtrado, defina o seu IP publico através do tfvars.

### OBS: Caso receba erros, devido falta de plugin e esteja rodando com ubuntu. Execute esse comando para baixar o plugin:
- curl "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/ubuntu_64bit/session-manager-plugin.deb" -o "session-manager-plugin.deb"

### Verificar status do cluster: 
- sudo kubectl get pods -n wordpress
- sudo kubectl get svc -n wordpress

### Verificar eventos do cluster
- sudo kubectl get events -n wordpress

### Verificar logs do WordPress
- sudo kubectl logs -n wordpress -l app=wordpress


## 📝 Limpeza do ambiente

```bash
terraform destroy
```

## CI/CD
#### O projeto inclui pipeline CI/CD com GitHub Actions para automatizar validação e deploy da infraestrutura.

#### Configuração do CI/CD
1. Configurar Secrets no GitHub
- Acesse: Settings → Secrets and variables → Actions → New repository secret
- SECRET: AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY

2. (Opcional) Configurar Backend Remoto S3
#### Para equipes ou CI/CD em produção, recomenda-se usar estado remoto:
- Executar script para criar bucket S3 + DynamoDB
- chmod +x scripts/setup-backend.sh
- ./scripts/setup-backend.sh

4. (Opcional) Configurar Environment Protection
- Para exigir aprovação antes do deploy:
- Settings → Environments → New environment

#### Como Usar o CI/CD
- Deploy via Pull Request (Recomendado)
1. Criar branch (Para este projeto deixei na branch main, realizar a edição no codigo para usar em outra branch)
git checkout -b feature/minha-alteracao

2. Fazer alterações
vim terraform/terraform.tfvars

3. Commit e push
- git add .
- git commit -m "feat: minha alteração"
- git push origin feature/minha-alteracao

4. Criar Pull Request no GitHub
-    → Pipeline executa Validate + Plan
-    → Comentário automático com o plano
-    → Revisar e aprovar PR
-    → Merge para main
-    → Apply automático

#### Terraform Plan
- Gera plano de execução
- Comenta no PR (se aplicável)
- Salva artifact do plano

#### Terraform Apply
- Executa apenas após merge na main
- Ou via execução manual
- Aplica as mudanças na AWS

####  Terraform Destroy
- Apenas via execução manual
- Requer environment destruction
- Remove toda a infraestrutura

### Observação Importante: 
- Temos um filtro no workflow que só dispara se mudar algo dentro do diretorio terraform/:
- paths: 'terraform/**'      #### Só dispara se mudar algo aqui
- '.github/workflows/**'

#### Isso foi criado para evitar execuções desnecessárias, mas pode ser alterado.
