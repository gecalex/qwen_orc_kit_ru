# DevOps Commands

## Описание
Команды для DevOps операций: деплой, инфраструктура, мониторинг.

## Доступные команды

### `devops deploy`
Развернуть приложение.

**Использование:**
```bash
devops deploy <environment> [--version tag] [--rollback]
```

**Опции:**
- `--version` - Версия для деплоя
- `--rollback` - Откатить к предыдущей версии

**Пример:**
```bash
devops deploy production --version v1.2.3
```

**Поддерживаемые окружения:**
- development
- staging
- production

---

### `devops infra`
Управление инфраструктурой.

**Использование:**
```bash
devops infra <action> [resource]
```

**Действия:**
- `plan` - Показать план изменений
- `apply` - Применить изменения
- `destroy` - Уничтожить ресурсы
- `state` - Показать состояние

**Пример:**
```bash
devops infra plan
devops infra apply
```

---

### `devops logs`
Просмотр логов.

**Использование:**
```bash
devops logs <service> [--follow] [--tail N]
```

**Опции:**
- `--follow` - Следить в реальном времени
- `--tail` - Количество строк

**Пример:**
```bash
devops logs api --follow --tail 100
```

---

### `devops scale`
Масштабировать сервис.

**Использование:**
```bash
devops scale <service> <replicas>
```

**Пример:**
```bash
devops scale api 5
```

---

### `devops status`
Проверить статус сервисов.

**Использование:**
```bash
devops status [--verbose]
```

**Опции:**
- `--verbose` - Подробная информация

**Пример:**
```bash
devops status --verbose
```

---

### `devops secrets`
Управление секретами.

**Использование:**
```bash
devops secrets <action> [name]
```

**Действия:**
- `list` - Список секретов
- `get <name>` - Получить секрет
- `set <name>` - Установить секрет
- `delete <name>` - Удалить секрет

**Пример:**
```bash
devops secrets set DATABASE_URL
```

---

### `devops metrics`
Получить метрики.

**Использование:**
```bash
devops metrics <service> [--period 1h|24h|7d]
```

**Опции:**
- `--period` - Период времени

**Пример:**
```bash
devops metrics api --period 24h
```

**Метрики:**
- CPU usage
- Memory usage
- Request rate
- Error rate
- Latency

---

### `devops health`
Проверить здоровье сервисов.

**Использование:**
```bash
devops health [service]
```

**Пример:**
```bash
devops health
devops health api
```

---

### `devops ci`
CI/CD операции.

**Использование:**
```bash
devops ci <action> [pipeline]
```

**Действия:**
- `run <pipeline>` - Запустить pipeline
- `status` - Статус pipeline
- `cancel <id>` - Отменить запуск
- `logs <id>` - Логи запуска

**Пример:**
```bash
devops ci run main-pipeline
```

---

## Конфигурация

### .devops.json
```json
{
  "provider": "kubernetes",
  "environments": {
    "development": {
      "namespace": "dev",
      "replicas": 1,
      "resources": {
        "cpu": "100m",
        "memory": "256Mi"
      }
    },
    "staging": {
      "namespace": "staging",
      "replicas": 2,
      "resources": {
        "cpu": "250m",
        "memory": "512Mi"
      }
    },
    "production": {
      "namespace": "prod",
      "replicas": 3,
      "resources": {
        "cpu": "500m",
        "memory": "1Gi"
      },
      "autoscaling": {
        "min": 3,
        "max": 10,
        "targetCPU": 70
      }
    }
  },
  "monitoring": {
    "prometheus": "http://prometheus:9090",
    "grafana": "http://grafana:3000"
  },
  "notifications": {
    "slack": {
      "enabled": true,
      "channel": "#deployments"
    }
  }
}
```

---

## CI/CD Интеграция

### GitHub Actions
```yaml
- name: Deploy to Production
  run: devops deploy production --version ${{ github.sha }}
  
- name: Health Check
  run: devops health api
```

---

## Best Practices

1. Используйте infrastructure as code
2. Автоматизируйте деплой
3. Мониторьте все сервисы
4. Настройте alerting
5. Делайте регулярные backup
