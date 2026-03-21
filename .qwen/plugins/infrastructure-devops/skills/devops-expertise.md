# DevOps Expertise Skill

## Описание
Навык эксперта DevOps: CI/CD, инфраструктура, контейнеризация, мониторинг.

## Компетенции

### CI/CD системы
- GitHub Actions
- GitLab CI
- Jenkins
- CircleCI
- Travis CI

### Контейнеризация
- Docker
- Docker Compose
- Container registries

### Оркестрация
- Kubernetes
- Helm
- Service mesh (Istio)

### Infrastructure as Code
- Terraform
- Ansible
- CloudFormation
- Pulumi

### Cloud платформы
- AWS
- Google Cloud
- Azure

### Мониторинг
- Prometheus
- Grafana
- ELK Stack
- Datadog

## Docker

### Dockerfile best practices
```dockerfile
# Multi-stage build
FROM python:3.11-slim as builder

WORKDIR /app
COPY requirements.txt .
RUN pip install --user --no-cache-dir -r requirements.txt

FROM python:3.11-slim

WORKDIR /app
COPY --from=builder /root/.local /root/.local
COPY . .

ENV PATH=/root/.local/bin:$PATH

USER nobody
CMD ["python", "-m", "uvicorn", "app.main:app"]
```

### Docker Compose
```yaml
version: '3.8'

services:
  app:
    build: .
    ports:
      - "8000:8000"
    environment:
      - DATABASE_URL=postgresql://db:5432/app
    depends_on:
      - db
    volumes:
      - .:/app
  
  db:
    image: postgres:15
    environment:
      - POSTGRES_PASSWORD=secret
    volumes:
      - postgres_data:/var/lib/postgresql/data

volumes:
  postgres_data:
```

## Kubernetes

### Основные ресурсы
```yaml
# Deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: myapp
  template:
    metadata:
      labels:
        app: myapp
    spec:
      containers:
      - name: app
        image: myapp:latest
        ports:
        - containerPort: 8000
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"

---
# Service
apiVersion: v1
kind: Service
metadata:
  name: app-service
spec:
  selector:
    app: myapp
  ports:
  - port: 80
    targetPort: 8000
  type: LoadBalancer

---
# Ingress
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: app-ingress
spec:
  rules:
  - host: app.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: app-service
            port:
              number: 80
```

### Helm Chart
```yaml
# Chart.yaml
apiVersion: v2
name: myapp
version: 1.0.0
appVersion: "1.0.0"

# values.yaml
replicaCount: 3
image:
  repository: myapp
  tag: latest
resources:
  limits:
    cpu: 500m
    memory: 512Mi
```

## Terraform

### AWS пример
```hcl
provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "app" {
  ami           = "ami-12345678"
  instance_type = "t3.medium"
  
  tags = {
    Name = "app-server"
  }
}

resource "aws_security_group" "app" {
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

output "instance_ip" {
  value = aws_instance.app.public_ip
}
```

## GitHub Actions

### CI/CD Pipeline
```yaml
name: CI/CD

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
    
    - name: Set up Python
      uses: actions/setup-python@v5
      with:
        python-version: '3.11'
    
    - name: Install dependencies
      run: pip install -r requirements.txt
    
    - name: Run tests
      run: pytest --cov=src
  
  build:
    needs: test
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
    
    - name: Build Docker image
      run: docker build -t myapp:${{ github.sha }} .
    
    - name: Push to registry
      run: |
        docker push myapp:${{ github.sha }}
  
  deploy:
    needs: build
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    steps:
    - name: Deploy to production
      run: |
        kubectl set image deployment/app app=myapp:${{ github.sha }}
```

## Мониторинг

### Prometheus config
```yaml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'app'
    static_configs:
      - targets: ['app:8000']
    metrics_path: '/metrics'
```

### Grafana dashboard
```json
{
  "dashboard": {
    "title": "App Metrics",
    "panels": [
      {
        "title": "Request Rate",
        "targets": [
          {
            "expr": "rate(http_requests_total[5m])"
          }
        ]
      }
    ]
  }
}
```

## MCP Integration

### Поиск DevOps библиотек
```
mcp__context7__resolve-library-id
  libraryName: "terraform"
  query: "Terraform AWS provider configuration"
```

## Выходные артефакты
- CI/CD конфигурации
- Dockerfile
- Kubernetes манифесты
- Terraform файлы
- Monitoring дашборды
