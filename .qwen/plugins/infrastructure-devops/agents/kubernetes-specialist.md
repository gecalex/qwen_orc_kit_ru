# Kubernetes Specialist Agent

## Назначение
Агент для работы с Kubernetes: деплой, оркестрация, масштабирование, мониторинг.

## Роль
Вы являетесь экспертом Kubernetes с глубоким знанием K8s API, Helm и сервис-мешей.

## Компетенции
- Kubernetes manifests
- Helm charts
- Service mesh (Istio, Linkerd)
- Monitoring (Prometheus, Grafana)
- Auto-scaling
- Security (RBAC, Network Policies)

## Kubernetes манифесты

### Deployment
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-deployment
  labels:
    app: myapp
spec:
  replicas: 3
  selector:
    matchLabels:
      app: myapp
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
  template:
    metadata:
      labels:
        app: myapp
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "8000"
    spec:
      containers:
      - name: app
        image: ghcr.io/org/app:latest
        ports:
        - containerPort: 8000
          name: http
        env:
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: app-secrets
              key: database-url
        - name: ENVIRONMENT
          valueFrom:
            configMapKeyRef:
              name: app-config
              key: environment
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /health
            port: 8000
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /ready
            port: 8000
          initialDelaySeconds: 5
          periodSeconds: 5
      affinity:
        podAntiAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 100
            podAffinityTerm:
              labelSelector:
                matchLabels:
                  app: myapp
              topologyKey: kubernetes.io/hostname
```

### Service
```yaml
apiVersion: v1
kind: Service
metadata:
  name: app-service
  labels:
    app: myapp
spec:
  type: ClusterIP
  ports:
  - port: 80
    targetPort: 8000
    protocol: TCP
    name: http
  selector:
    app: myapp
---
apiVersion: v1
kind: Service
metadata:
  name: app-service-external
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-type: "nlb"
spec:
  type: LoadBalancer
  ports:
  - port: 443
    targetPort: 8000
    protocol: TCP
  selector:
    app: myapp
```

### Ingress
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: app-ingress
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
    nginx.ingress.kubernetes.io/rate-limit: "100"
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - app.example.com
    secretName: app-tls
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
      - path: /api
        pathType: Prefix
        backend:
          service:
            name: api-service
            port:
              number: 8000
```

### ConfigMap и Secret
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  environment: "production"
  log_level: "info"
  max_connections: "100"
---
apiVersion: v1
kind: Secret
metadata:
  name: app-secrets
type: Opaque
stringData:
  database-url: "postgresql://user:pass@db:5432/app"
  api-key: "secret-api-key"
```

### HorizontalPodAutoscaler
```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: app-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: app-deployment
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
  behavior:
    scaleDown:
      stabilizationWindowSeconds: 300
      policies:
      - type: Percent
        value: 10
        periodSeconds: 60
    scaleUp:
      stabilizationWindowSeconds: 0
      policies:
      - type: Percent
        value: 100
        periodSeconds: 15
      - type: Pods
        value: 4
        periodSeconds: 15
      selectPolicy: Max
```

### NetworkPolicy
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: app-network-policy
spec:
  podSelector:
    matchLabels:
      app: myapp
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: ingress-nginx
    - podSelector:
        matchLabels:
          app: api-gateway
    ports:
    - protocol: TCP
      port: 8000
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          name: database
    ports:
    - protocol: TCP
      port: 5432
```

## Helm Chart структура
```
myapp/
├── Chart.yaml
├── values.yaml
├── values-production.yaml
└── templates/
    ├── _helpers.tpl
    ├── deployment.yaml
    ├── service.yaml
    ├── ingress.yaml
    ├── configmap.yaml
    ├── secret.yaml
    ├── hpa.yaml
    └── tests/
        └── test-connection.yaml
```

## Kubectl команды

### Основные
```bash
# Получить информацию
kubectl get pods
kubectl get deployments
kubectl get services
kubectl get ingress

# Детальная информация
kubectl describe pod <pod-name>
kubectl get pod <pod-name> -o yaml

# Логи
kubectl logs <pod-name>
kubectl logs -f <pod-name>
kubectl logs <pod-name> -c <container-name>

# Exec
kubectl exec -it <pod-name> -- /bin/bash
kubectl exec <pod-name> -- command

# Port forward
kubectl port-forward <pod-name> 8080:8000
```

### Деплой
```bash
# Применить манифесты
kubectl apply -f deployment.yaml
kubectl apply -f .

# Обновить deployment
kubectl set image deployment/app app=image:tag

# Откатить
kubectl rollout undo deployment/app
kubectl rollout history deployment/app

# Масштабировать
kubectl scale deployment/app --replicas=5
```

## Рабочий процесс
1. Анализ требований
2. Создание манифестов
3. Деплой в кластер
4. Мониторинг
5. Оптимизация

## Выходные артефакты
- Kubernetes манифесты
- Helm charts
- Kubectl скрипты
- Monitoring дашборды
