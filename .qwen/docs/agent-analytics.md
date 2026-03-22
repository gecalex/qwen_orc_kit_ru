# Agent Analytics

Система аналитики агентов для Qwen Orchestrator Kit.

## Обзор

Agent Analytics предоставляет комплексный анализ вызовов агентов, выявление паттернов и аномалий, а также генерацию визуальных дашбордов для мониторинга производительности системы.

```
┌─────────────────────────────────────────────────────────────────┐
│                    Agent Analytics v1.0.0                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────┐  │
│  │   Agent Call     │  │   Generate       │  │   Detect     │  │
│  │   Analyzer       │  │   Dashboard      │  │   Anomalies  │  │
│  │                  │  │                  │  │              │  │
│  │  - Подсчет       │  │  - Визуализация  │  │  - Зависания │  │
│  │  - Метрики       │  │  - Heatmap       │  │  - Повторы   │  │
│  │  - Аномалии      │  │  - Тренды        │  │  - Циклы     │  │
│  └──────────────────┘  └──────────────────┘  └──────────────┘  │
│         │                     │                    │            │
│         └─────────────────────┼────────────────────┘            │
│                               │                                  │
│                    ┌──────────▼──────────┐                       │
│                    │   Reports &         │                       │
│                    │   Dashboards        │                       │
│                    └─────────────────────┘                       │
└─────────────────────────────────────────────────────────────────┘
```

## Структура

```
.qwen/analytics/
├── agent-call-analyzer.sh      # Анализ вызовов агентов
├── generate-agent-dashboard.sh # Генерация дашбордов
├── detect-anomalies.sh         # Обнаружение аномалий
└── reports/                    # Сгенерированные отчеты
```

## Быстрый старт

### Полный анализ

```bash
# Запуск всех анализаторов
.qwen/analytics/agent-call-analyzer.sh

# Генерация дашборда
.qwen/analytics/generate-agent-dashboard.sh

# Обнаружение аномалий
.qwen/analytics/detect-anomalies.sh
```

### Интеграция с Feedback System

```bash
# Запуск через Feedback System
.qwen/feedback/generate-all.sh

# Пропустить аналитику
.qwen/feedback/generate-all.sh --skip-analytics
```

## Компоненты

### 1. Agent Call Analyzer

**Назначение:** Анализ вызовов агентов и выявление паттернов

**Функционал:**
- Чтение логов из `.qwen/logs/agent-calls.log`
- Подсчет вызовов по агентам
- Выявление аномалий (повторные вызовы, долгие задачи)
- Расчет метрик (среднее время, успех/ошибка)
- Генерация JSON и Markdown отчетов

**Использование:**
```bash
# Базовый запуск
.qwen/analytics/agent-call-analyzer.sh

# Подробный вывод
.qwen/analytics/agent-call-analyzer.sh -v

# Тихий режим (только JSON)
.qwen/analytics/agent-call-analyzer.sh -q

# Кастомный файл логов
.qwen/analytics/agent-call-analyzer.sh -l /path/to/log.log

# Вывод в другую директорию
.qwen/analytics/agent-call-analyzer.sh -o /tmp/analytics
```

**Выходные данные:**
```
Agent Call Statistics:
- orc_planning_task_analyzer: 15 вызовов (93% успех)
- orc_dev_task_coordinator: 42 вызова (88% успех)
- bug-hunter: 8 вызовов (100% успех)

Anomalies Detected:
- ⚠️ work_testing_test_generator: 5 повторных вызовов
- ⚠️ orc_testing_quality_assurer: среднее время 12 мин (>5 мин)

Performance Metrics:
- Среднее время выполнения: 4.2 мин
- Успешность: 91%
- Пиковая нагрузка: 14:00-16:00
```

**Формат логов:**
```
timestamp|agent|status|task|result|duration|tokens
2026-03-21T09:00:00Z|orc_planning_task_analyzer|started|task_001|Phase 0 Planning
2026-03-21T09:02:30Z|orc_planning_task_analyzer|completed|task_001|success|150s|tokens:4500
```

### 2. Generate Agent Dashboard

**Назначение:** Генерация дашборда с метриками

**Функционал:**
- Визуализация метрик агентов
- Тренды по времени
- Heatmap нагрузки
- Топ проблемных агентов
- Рекомендации по оптимизации

**Использование:**
```bash
# HTML дашборд (по умолчанию)
.qwen/analytics/generate-agent-dashboard.sh

# Markdown дашборд
.qwen/analytics/generate-agent-dashboard.sh -f md

# Оба формата
.qwen/analytics/generate-agent-dashboard.sh -f both

# Использовать готовый анализ
.qwen/analytics/generate-agent-dashboard.sh -a analysis.json
```

**Выходные данные:**
- HTML дашборд с интерактивной визуализацией
- Markdown версия для документации

### 3. Detect Anomalies

**Назначение:** Обнаружение аномалий в работе агентов

**Типы обнаруживаемых аномалий:**

| Тип | Описание | Порог | Серьезность |
|-----|----------|-------|-------------|
| 🚨 Timeout | Зависание агента | > 5 мин | High |
| ⚠️ Repeat Calls | Повторные вызовы | > 3 раз | Medium |
| 🔄 Cyclic Calls | Циклические вызовы | A → B → A | High |
| 📊 Unusual Pattern | Необычный паттерн | > 3σ отклонение | Low |

**Использование:**
```bash
# Базовый запуск
.qwen/analytics/detect-anomalies.sh

# Подробный вывод
.qwen/analytics/detect-anomalies.sh -v

# Тихий режим
.qwen/analytics/detect-anomalies.sh -q
```

**Выходные данные:**
```json
{
  "timestamp": "2026-03-21_10-30-00",
  "summary": {
    "total_anomalies": 5,
    "timeout_count": 2,
    "repeat_calls_count": 2,
    "cyclic_calls_count": 0,
    "unusual_patterns_count": 1,
    "overall_severity": "high"
  },
  "anomalies": {
    "timeouts": [...],
    "repeat_calls": [...],
    "cyclic_calls": [...],
    "unusual_patterns": [...]
  }
}
```

## Метрики

### Ключевые метрики

| Метрика | Описание | Формула |
|---------|----------|---------|
| Success Rate | Успешность вызовов | (Успех / Всего) × 100 |
| Avg Response Time | Среднее время ответа | Σ(время) / N |
| Error Rate | Частота ошибок | (Ошибки / Всего) × 100 |
| Token Efficiency | Эффективность токенов | (Полезные / Всего) × 100 |
| Agent Utilization | Утилизация агентов | (Активные / Всего) × 100 |

### Целевые значения

| Метрика | Цель | Критично |
|---------|------|----------|
| Success Rate | ≥95% | <80% |
| Avg Response Time | <60с | >300с |
| Error Rate | <5% | >20% |
| Token Efficiency | ≥80% | <50% |

## Форматы отчетов

### JSON отчеты

Структура JSON отчета:
```json
{
  "timestamp": "2026-03-21_10-30-00",
  "date": "2026-03-21",
  "summary": {
    "total_calls": 100,
    "total_success": 92,
    "total_failed": 8,
    "success_rate": 92,
    "average_time_seconds": 250,
    "total_time_seconds": 25000,
    "total_tokens": 500000,
    "peak_hour": "14:00"
  },
  "agents": {
    "orc_planning_task_analyzer": {
      "calls": 15,
      "success": 14,
      "failed": 1,
      "success_rate": 93,
      "total_time_seconds": 2250,
      "total_tokens": 67500
    }
  },
  "anomalies": [...]
}
```

### Markdown отчеты

Структура Markdown отчета:
```markdown
# Agent Call Analysis Report

**Дата**: 2026-03-21

## Executive Summary
| Метрика | Значение |
|---------|----------|
| Всего вызовов | 100 |
| Успешность | 92% |

## Agent Call Statistics
| Агент | Вызовы | Успех | Ошибки |
|-------|--------|-------|--------|
| orc_* | 15 | 14 | 1 |

## Anomalies Detected
- ⚠️ agent: описание

## Recommendations
1. Рекомендация 1
2. Рекомендация 2
```

## Интеграция

### Логирование вызовов агентов

Добавьте логирование в оркестраторы:

```markdown
### Post-Task Analytics
- Логирование вызова в agent-calls.log
- Отправка метрик в analytics
- Проверка чек-листов после задачи
```

**Формат записи в лог:**
```bash
echo "$(date -Iseconds)|$AGENT_NAME|started|$TASK_ID|$DESCRIPTION" >> .qwen/logs/agent-calls.log
# После завершения
echo "$(date -Iseconds)|$AGENT_NAME|completed|$TASK_ID|$STATUS|${DURATION}s|tokens:${TOKENS}" >> .qwen/logs/agent-calls.log
```

### CI/CD Pipeline

```yaml
# GitHub Actions
name: Agent Analytics

on:
  schedule:
    - cron: '0 */6 * * *'  # Каждые 6 часов

jobs:
  analytics:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Run Agent Analytics
        run: |
          .qwen/analytics/agent-call-analyzer.sh -q
          .qwen/analytics/detect-anomalies.sh -q
      
      - name: Upload Reports
        uses: actions/upload-artifact@v3
        with:
          name: agent-analytics
          path: .qwen/analytics/reports/
```

### Grafana Dashboard

Импортируйте метрики из JSON:

```json
{
  "dashboard": {
    "panels": [
      {
        "title": "Agent Success Rate",
        "targets": [{"expr": "agent_success_rate"}]
      },
      {
        "title": "Average Response Time",
        "targets": [{"expr": "agent_avg_response_time"}]
      }
    ]
  }
}
```

## Troubleshooting

### Проблемы и решения

**Проблема:** Файл логов не найден
```bash
# Создать тестовые данные
.qwen/analytics/agent-call-analyzer.sh
```

**Проблема:** jq не найден
```bash
apt-get install jq  # или brew install jq
```

**Проблема:** Нет данных для анализа
- Проверьте, что агенты логируют вызовы
- Убедитесь, что формат логов корректен

**Проблема:** Ложные аномалии
- Настройте пороги в detect-anomalies.sh
- Используйте `--skip-*` опции

## Опции командной строки

### agent-call-analyzer.sh

| Опция | Описание |
|-------|----------|
| `-h, --help` | Показать справку |
| `-v, --verbose` | Подробный вывод |
| `-q, --quiet` | Тихий режим |
| `-o, --output DIR` | Директория вывода |
| `-l, --log FILE` | Файл логов |

### generate-agent-dashboard.sh

| Опция | Описание |
|-------|----------|
| `-h, --help` | Показать справку |
| `-v, --verbose` | Подробный вывод |
| `-q, --quiet` | Тихий режим |
| `-o, --output DIR` | Директория вывода |
| `-f, --format FORMAT` | Формат: html, md, both |
| `-a, --analysis FILE` | JSON файл анализа |

### detect-anomalies.sh

| Опция | Описание |
|-------|----------|
| `-h, --help` | Показать справку |
| `-v, --verbose` | Подробный вывод |
| `-q, --quiet` | Тихий режим |
| `-o, --output DIR` | Директория вывода |
| `-l, --log FILE` | Файл логов |

## Версии

| Версия | Дата | Изменения |
|--------|------|-----------|
| 1.0.0 | 2026-03-21 | Initial release |

---

*Документация сгенерирована для Agent Analytics v1.0.0*
