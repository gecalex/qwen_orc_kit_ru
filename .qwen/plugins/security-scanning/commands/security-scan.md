# Security Scan Commands

## Описание
Команды для сканирования безопасности: анализ кода, зависимостей, уязвимостей.

## Доступные команды

### `security-scan code`
Сканировать код на уязвимости.

**Использование:**
```bash
security-scan code [path] [--format json|html|sarif] [--output file]
```

**Опции:**
- `--format` - Формат отчета (json, html, sarif)
- `--output` - Сохранить отчет в файл
- `--severity` - Минимальный уровень серьезности (low, medium, high, critical)

**Пример:**
```bash
security-scan code src/ --format json --output security-report.json
```

**Инструменты:**
- bandit (Python security)
- semgrep (pattern matching)
- trufflehog (secrets detection)

---

### `security-scan dependencies`
Сканировать зависимости на уязвимости.

**Использование:**
```bash
security-scan dependencies [--dev] [--format json|table]
```

**Опции:**
- `--dev` - Включить dev зависимости
- `--format` - Формат отчета

**Пример:**
```bash
security-scan dependencies --format json
```

**Инструменты:**
- safety (Python)
- snyk (multi-language)
- osv-scanner (Google OSV)

---

### `security-scan full`
Полное сканирование безопасности.

**Использование:**
```bash
security-scan full [--output-dir reports/]
```

**Включает:**
- Сканирование кода
- Сканирование зависимостей
- Проверку конфигураций
- Поиск secrets

**Пример:**
```bash
security-scan full --output-dir security-reports/
```

---

### `security-scan secrets`
Поиск утечек secrets в коде.

**Использование:**
```bash
security-scan secrets [path] [--history]
```

**Опции:**
- `--history` - Сканировать git историю

**Пример:**
```bash
security-scan secrets . --history
```

**Обнаруживает:**
- API keys
- Passwords
- Private keys
- Tokens
- Credentials

---

### `security-scan config`
Проверка конфигураций безопасности.

**Использование:**
```bash
security-scan config [files...]
```

**Проверяет:**
- Dockerfile best practices
- Kubernetes security contexts
- Cloud IAM policies
- Web security headers

**Пример:**
```bash
security-scan config Dockerfile k8s/deployment.yaml
```

---

### `security-scan report`
Сгенерировать сводный отчет.

**Использование:**
```bash
security-scan report [--format markdown|html|pdf] [--since date]
```

**Пример:**
```bash
security-scan report --format markdown --since 2026-01-01
```

---

### `security-scan fix`
Автоматически исправить уязвимости.

**Использование:**
```bash
security-scan fix [--dry-run] [--severity high,critical]
```

**Опции:**
- `--dry-run` - Показать что будет исправлено
- `--severity` - Уровни для исправления

**Пример:**
```bash
security-scan fix --severity critical
```

**Автоматические исправления:**
- Обновление уязвимых зависимостей
- Удаление hardcoded secrets
- Исправление insecure configurations

---

## Конфигурация

### .security-scan.json
```json
{
  "scanners": {
    "bandit": {
      "enabled": true,
      "excludePaths": ["tests/", "venv/"]
    },
    "safety": {
      "enabled": true,
      "ignoreVulnerabilities": []
    },
    "semgrep": {
      "enabled": true,
      "rules": ["p/security-audit", "p/owasp-top-10"]
    }
  },
  "thresholds": {
    "critical": 0,
    "high": 0,
    "medium": 5,
    "low": 10
  },
  "reporting": {
    "format": "json",
    "outputDir": "security-reports/"
  }
}
```

---

## CI/CD Интеграция

### GitHub Actions
```yaml
- name: Security Scan
  run: |
    security-scan code --format sarif --output security.sarif
    security-scan dependencies --format json
    
- name: Upload SARIF
  uses: github/codeql-action/upload-sarif@v2
  with:
    sarif_file: security.sarif
```

---

## Выходные форматы

### JSON отчет
```json
{
  "scanDate": "2026-03-21T10:00:00Z",
  "summary": {
    "total": 10,
    "critical": 1,
    "high": 2,
    "medium": 3,
    "low": 4
  },
  "findings": [...]
}
```

---

## Best Practices

1. Запускайте сканирование в CI/CD
2. Блокируйте merge при critical уязвимостях
3. Регулярно обновляйте зависимости
4. Не храните secrets в коде
5. Используйте .env файлы для конфигурации
