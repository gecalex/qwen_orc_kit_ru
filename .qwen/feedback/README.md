# Feedback System

Комплексная система автоматического анализа и отчетности для Qwen Code Orchestrator Kit.

## Обзор

Feedback System предоставляет автоматизированный анализ проекта по 5 ключевым областям с генерацией стандартизированных отчетов и метрик для дашбордов.

```
┌─────────────────────────────────────────────────────────────────┐
│                    Feedback System v1.0.0                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │    Git       │  │    Spec      │  │   Agent      │          │
│  │   Workflow   │  │ Compliance   │  │ Interaction  │          │
│  │  Analyzer    │  │  Analyzer    │  │  Analyzer    │          │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘          │
│         │                 │                 │                   │
│         └─────────────────┼─────────────────┘                   │
│                           │                                     │
│  ┌──────────────┐  ┌──────▼───────┐  ┌──────────────┐          │
│  │   Quality    │  │   Logic      │  │   Generate   │          │
│  │   Trends     │  │ Consistency  │  │   Reports    │          │
│  │  Analyzer    │  │  Analyzer    │  │   & Metrics  │          │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘          │
│         │                 │                 │                   │
│         └─────────────────┼─────────────────┘                   │
│                           │                                     │
│                    ┌──────▼───────┐                             │
│                    │   Summary    │                             │
│                    │   Report     │                             │
│                    └──────────────┘                             │
└─────────────────────────────────────────────────────────────────┘
```

## Структура

```
.qwen/feedback/
├── analyzers/           # Скрипты анализа
│   ├── git-workflow-analyzer.sh
│   ├── spec-compliance-analyzer.sh
│   ├── agent-interaction-analyzer.sh
│   ├── logic-consistency-analyzer.sh
│   └── quality-trends-analyzer.sh
├── reporters/           # Генерация отчетов
│   ├── generate-feedback-report.sh
│   └── generate-metrics.sh
├── checklists/          # Чек-листы для проверок
│   ├── git-workflow-checklist.md
│   ├── specification-checklist.md
│   ├── agent-interaction-checklist.md
│   └── logic-consistency-checklist.md
├── reports/             # Сгенерированные отчеты
├── generate-all.sh      # Главный скрипт
└── README.md            # Эта документация
```

## Быстрый старт

### Запуск всех проверок

```bash
# Полный запуск со всеми проверками
.qwen/feedback/generate-all.sh

# Запуск с выводом в другую директорию
.qwen/feedback/generate-all.sh -o /tmp/reports

# Только JSON формат метрик
.qwen/feedback/generate-all.sh -f json
```

### Запуск отдельных анализаторов

```bash
# Git Workflow анализ
.qwen/feedback/analyzers/git-workflow-analyzer.sh

# Spec Compliance анализ
.qwen/feedback/analyzers/spec-compliance-analyzer.sh

# Agent Interaction анализ
.qwen/feedback/analyzers/agent-interaction-analyzer.sh

# Logic Consistency анализ
.qwen/feedback/analyzers/logic-consistency-analyzer.sh

# Quality Trends анализ
.qwen/feedback/analyzers/quality-trends-analyzer.sh
```

### Генерация отчетов

```bash
# Генерация сводного Markdown отчета
.qwen/feedback/reporters/generate-feedback-report.sh

# Генерация метрик для дашборда
.qwen/feedback/reporters/generate-metrics.sh -f both
```

## Анализаторы

### 1. Git Workflow Analyzer

**Назначение:** Анализ нарушений git workflow

**Проверки:**
- Работа в main/dev напрямую
- Отсутствие feature-веток
- Коммиты без pre-commit review
- Отсутствие тегов
- Незакоммиченные изменения

**Выход:** JSON с нарушениями и рекомендациями

**Пример использования:**
```bash
.qwen/feedback/analyzers/git-workflow-analyzer.sh -v
```

**Пример вывода:**
```json
{
  "timestamp": "2026-03-21_10-30-00",
  "score": 85,
  "grade": "B",
  "warnings": ["Работа в защищенной ветке: main"],
  "recommendations": ["Используйте feature-ветки"]
}
```

### 2. Spec Compliance Analyzer

**Назначение:** Проверка соответствия спецификациям

**Проверки:**
- Наличие spec.md
- Соответствие реализации spec
- Полнота документации
- Тестируемость требований

**Выход:** JSON с compliance метриками

### 3. Agent Interaction Analyzer

**Назначение:** Анализ взаимодействия агентов

**Проверки:**
- Паттерны вызовов агентов
- Аномалии (зависания, повторные вызовы)
- Эффективность (время, токены)
- Ошибки агентов

**Выход:** JSON с метриками и паттернами

### 4. Logic Consistency Analyzer

**Назначение:** Проверка логической целостности

**Проверки:**
- Противоречия в документации
- Несостыковки в путях
- Дублирование логики
- Мертвый код

**Выход:** JSON с противоречиями

### 5. Quality Trends Analyzer

**Назначение:** Анализ трендов качества

**Проверки:**
- Метрики Quality Gates
- Тренды по времени
- Прогнозы проблем
- Статистика исправлений

**Выход:** JSON с трендами

## Опции командной строки

### generate-all.sh

| Опция | Описание |
|-------|----------|
| `-h, --help` | Показать справку |
| `-v, --verbose` | Подробный вывод |
| `-q, --quiet` | Тихий режим |
| `-o, --output DIR` | Директория для вывода |
| `-f, --format FORMAT` | Формат: md, json, both |
| `--skip-git` | Пропустить Git Workflow |
| `--skip-spec` | Пропустить Spec Compliance |
| `--skip-agent` | Пропустить Agent Interaction |
| `--skip-logic` | Пропустить Logic Consistency |
| `--skip-quality` | Пропустить Quality Trends |
| `--skip-report` | Пропустить генерацию отчета |
| `--skip-metrics` | Пропустить генерацию метрик |
| `--only-analyzers` | Только анализаторы |
| `--only-reporters` | Только генераторы |

### Анализаторы

| Опция | Описание |
|-------|----------|
| `-h, --help` | Показать справку |
| `-v, --verbose` | Подробный вывод |
| `-q, --quiet` | Тихий режим (только JSON) |
| `-o, --output DIR` | Директория для вывода |

## Форматы отчетов

### JSON отчеты анализаторов

Каждый анализатор генерирует JSON файл со структурой:

```json
{
  "timestamp": "2026-03-21_10-30-00",
  "status": "completed",
  "analyzer": "git-workflow-analyzer",
  "version": "1.0.0",
  "violations": [],
  "warnings": [],
  "recommendations": [],
  "metrics": {...},
  "score": 85,
  "grade": "B"
}
```

### Markdown сводный отчет

Структура отчета:

```markdown
# Feedback Report: 2026-03-21

## Executive Summary
- Общая оценка
- Scores по областям
- Критические проблемы

## Git Workflow Analysis
## Specification Compliance
## Agent Interaction
## Logic Consistency
## Quality Trends

## Action Items
- Priority 0 (критичное)
- Priority 1 (важное)
- Priority 2 (желательное)
```

### Метрики для дашборда

**JSON формат:**
```json
{
  "overall": {
    "average_score": 85,
    "status": "healthy"
  },
  "categories": {
    "git_workflow": {"score": 90, "grade": "A"},
    "spec_compliance": {"score": 80, "grade": "B"}
  }
}
```

**CSV формат:**
```csv
timestamp,category,score,grade,metric1_name,metric1_value
2026-03-21,git_workflow,90,A,violations,0
```

## Чек-листы

Система включает 4 чек-листа для ручных проверок:

1. **git-workflow-checklist.md** - 50 пунктов проверки git workflow
2. **specification-checklist.md** - 50 пунктов проверки спецификаций
3. **agent-interaction-checklist.md** - 50 пунктов проверки агентов
4. **logic-consistency-checklist.md** - 50 пунктов проверки целостности

Каждый чек-лист включает:
- Подробные пункты проверки
- Метрики для оценки
- Рекомендации по использованию

## Интеграция

### CI/CD Pipeline

```yaml
# Пример для GitHub Actions
name: Feedback Analysis

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  feedback:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Run Feedback Analysis
        run: .qwen/feedback/generate-all.sh -q
      
      - name: Upload Reports
        uses: actions/upload-artifact@v3
        with:
          name: feedback-reports
          path: .qwen/feedback/reports/
```

### Grafana Dashboard

Импортируйте метрики из JSON файлов:

```json
{
  "dashboard": {
    "panels": [
      {
        "title": "Overall Score",
        "targets": [{"expr": "feedback_overall_score"}]
      }
    ]
  }
}
```

### Prometheus Metrics

Экспорт метрик в Prometheus формат:

```bash
# Конвертация JSON в Prometheus format
jq -r '.categories | to_entries[] | "feedback_\(.key)_score \(.value.score)"' metrics.json
```

## Зависимости

- **bash** 4.0+
- **jq** - для обработки JSON
- **git** - для git анализа

### Установка зависимостей

```bash
# Debian/Ubuntu
apt-get install jq git

# macOS
brew install jq git

# Fedora
dnf install jq git
```

## Примеры использования

### Ежедневный анализ

```bash
# Добавить в crontab
0 9 * * * /path/to/.qwen/feedback/generate-all.sh -q
```

### Пре-релизная проверка

```bash
# Полный анализ перед релизом
.qwen/feedback/generate-all.sh -v -o ./release-reports
```

### Проверка конкретного аспекта

```bash
# Только проверка агентов
.qwen/feedback/generate-all.sh --skip-git --skip-spec --skip-logic --skip-quality
```

### Интеграция с другими инструментами

```bash
# После запуска анализаторов, использовать навыки
skill: "code-quality-checker"
skill: "bug-hunter"
```

## Интерпретация результатов

### Оценки (Grades)

| Grade | Score | Статус |
|-------|-------|--------|
| A | 90-100 | Отлично |
| B | 80-89 | Хорошо |
| C | 70-79 | Удовлетворительно |
| D | 60-69 | Требует улучшения |
| F | 0-59 | Критические проблемы |

### Priority уровней

- **Priority 0** - Критичные проблемы, требуют немедленного внимания
- **Priority 1** - Важные проблемы, следует исправить в ближайшем спринте
- **Priority 2** - Желательные улучшения, можно отложить

## Troubleshooting

### Проблемы и решения

**Проблема:** Скрипты не исполняемые
```bash
chmod +x .qwen/feedback/**/*.sh
```

**Проблема:** jq не найден
```bash
apt-get install jq  # или brew install jq
```

**Проблема:** Отчеты не генерируются
- Проверьте, что анализаторы успешно завершены
- Проверьте права на запись в директорию output

**Проблема:** Ложные срабатывания
- Настройте исключения в скриптах анализаторов
- Используйте `--skip-*` опции для пропуска проверок

## Вклад в развитие

### Добавление нового анализатора

1. Создайте скрипт в `.qwen/feedback/analyzers/`
2. Реализуйте интерфейс:
   - Поддержка `-h, -v, -q, -o` опций
   - Генерация JSON отчета
   - Возврат кода успеха/ошибки
3. Обновите `generate-all.sh`
4. Добавьте чек-лист при необходимости

### Обновление чек-листов

1. Откройте соответствующий файл в `checklists/`
2. Добавьте новые пункты
3. Обновите версию и дату

## Лицензия

Система является частью Qwen Code Orchestrator Kit.

## Версии

| Версия | Дата | Изменения |
|--------|------|-----------|
| 1.0.0 | 2026-03-21 | Initial release |

---

*Документация сгенерирована для Feedback System v1.0.0*
