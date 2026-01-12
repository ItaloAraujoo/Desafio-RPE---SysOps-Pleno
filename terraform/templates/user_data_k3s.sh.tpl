#!/bin/bash
set -e
exec > /var/log/user-data.log 2>&1

echo "=========================================="
echo "Iniciando configuracao da instancia EC2"
echo "Data: $(date)"
echo "Hostname: $(hostname)"
echo "=========================================="

# Variáveis do Terraform
export MYSQL_ROOT_PASSWORD="${mysql_root_password}"
export MYSQL_DATABASE="${mysql_database}"
export MYSQL_USER="${mysql_user}"
export MYSQL_PASSWORD="${mysql_user_password}"
export WORDPRESS_PORT="${wordpress_port}"
export RDS_ENDPOINT="${rds_endpoint}"

echo "[1/7] Atualizando sistema..."
apt-get update -y
DEBIAN_FRONTEND=noninteractive apt-get upgrade -y

echo "[2/7] Instalando dependencias..."
apt-get install -y curl wget apt-transport-https ca-certificates

echo "[3/7] Garantindo SSM Agent..."
snap install amazon-ssm-agent --classic || true
systemctl enable snap.amazon-ssm-agent.amazon-ssm-agent.service || true
systemctl start snap.amazon-ssm-agent.amazon-ssm-agent.service || true

echo "[4/7] Instalando K3s..."
curl -sfL https://get.k3s.io | sh -s - --write-kubeconfig-mode 644

echo "Aguardando K3s inicializar..."
sleep 30

# Configurar kubectl para root
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
echo "export KUBECONFIG=/etc/rancher/k3s/k3s.yaml" >> /root/.bashrc

# Verificar se K3s está rodando
kubectl get nodes
kubectl cluster-info

echo "[5/7] Criando manifests Kubernetes..."
mkdir -p /opt/kubernetes
cd /opt/kubernetes

# Namespace
cat > namespace.yaml << 'ENDOFFILE'
apiVersion: v1
kind: Namespace
metadata:
  name: wordpress
  labels:
    app: wordpress
    environment: production
ENDOFFILE

# ConfigMap com endpoint do RDS
cat > configmap.yaml << ENDOFFILE
apiVersion: v1
kind: ConfigMap
metadata:
  name: wordpress-config
  namespace: wordpress
data:
  WORDPRESS_DB_HOST: "${rds_endpoint}"
  WORDPRESS_DB_NAME: "${mysql_database}"
  WORDPRESS_TABLE_PREFIX: "wp_"
ENDOFFILE

# Secret com credenciais
cat > secret.yaml << ENDOFFILE
apiVersion: v1
kind: Secret
metadata:
  name: mysql-secret
  namespace: wordpress
type: Opaque
stringData:
  MYSQL_ROOT_PASSWORD: "${mysql_root_password}"
  MYSQL_DATABASE: "${mysql_database}"
  MYSQL_USER: "admin"
  MYSQL_PASSWORD: "${mysql_root_password}"
ENDOFFILE

# PVC para WordPress
cat > wordpress-pvc.yaml << 'ENDOFFILE'
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: wordpress-pvc
  namespace: wordpress
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: local-path
  resources:
    requests:
      storage: 5Gi
ENDOFFILE

# Deployment do WordPress
cat > wordpress-deployment.yaml << 'ENDOFFILE'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: wordpress
  namespace: wordpress
  labels:
    app: wordpress
spec:
  replicas: 1
  selector:
    matchLabels:
      app: wordpress
  template:
    metadata:
      labels:
        app: wordpress
    spec:
      containers:
      - name: wordpress
        image: wordpress:latest
        ports:
        - containerPort: 80
          name: http
        env:
        - name: WORDPRESS_DB_HOST
          valueFrom:
            configMapKeyRef:
              name: wordpress-config
              key: WORDPRESS_DB_HOST
        - name: WORDPRESS_DB_NAME
          valueFrom:
            configMapKeyRef:
              name: wordpress-config
              key: WORDPRESS_DB_NAME
        - name: WORDPRESS_DB_USER
          valueFrom:
            secretKeyRef:
              name: mysql-secret
              key: MYSQL_USER
        - name: WORDPRESS_DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: mysql-secret
              key: MYSQL_PASSWORD
        - name: WORDPRESS_TABLE_PREFIX
          valueFrom:
            configMapKeyRef:
              name: wordpress-config
              key: WORDPRESS_TABLE_PREFIX
        resources:
          limits:
            cpu: "1000m"
            memory: "1Gi"
          requests:
            cpu: "250m"
            memory: "256Mi"
        volumeMounts:
        - name: wordpress-storage
          mountPath: /var/www/html
        livenessProbe:
          httpGet:
            path: /wp-admin/install.php
            port: 80
          initialDelaySeconds: 120
          periodSeconds: 10
          timeoutSeconds: 5
        readinessProbe:
          httpGet:
            path: /wp-admin/install.php
            port: 80
          initialDelaySeconds: 60
          periodSeconds: 5
          timeoutSeconds: 5
      volumes:
      - name: wordpress-storage
        persistentVolumeClaim:
          claimName: wordpress-pvc
ENDOFFILE

# Service NodePort
cat > wordpress-service.yaml << ENDOFFILE
apiVersion: v1
kind: Service
metadata:
  name: wordpress-service
  namespace: wordpress
spec:
  type: NodePort
  selector:
    app: wordpress
  ports:
  - port: 80
    targetPort: 80
    nodePort: ${wordpress_port}
ENDOFFILE

echo "[6/7] Aplicando manifests..."
kubectl apply -f namespace.yaml
kubectl apply -f configmap.yaml
kubectl apply -f secret.yaml
kubectl apply -f wordpress-pvc.yaml
kubectl apply -f wordpress-deployment.yaml
kubectl apply -f wordpress-service.yaml

echo "[7/7] Aguardando pods ficarem prontos..."
kubectl wait --for=condition=Ready pod -l app=wordpress -n wordpress --timeout=300s || true

echo "=========================================="
echo "Status Final:"
kubectl get all -n wordpress
echo "=========================================="
echo "Verificando conectividade com RDS..."
kubectl run test-mysql --image=mysql:8.0 --rm -it --restart=Never -n wordpress -- \
  mysql -h ${rds_endpoint} -u admin -p${mysql_root_password} -e "SELECT 1;" 2>/dev/null || echo "Teste de conexao executado"
echo "=========================================="
echo "WordPress implantado com sucesso!"
echo "Porta NodePort: ${wordpress_port}"
echo "RDS Endpoint: ${rds_endpoint}"
echo "=========================================="
