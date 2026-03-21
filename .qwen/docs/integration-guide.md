# Руководство по интеграции компонентов

**Версия:** 1.0.0  
**Дата:** 21 марта 2026  
**Статус:** Активный  
**Проект:** Qwen Code Orchestrator Kit v0.6.0

---

## Содержание

1. [Архитектура системы](#1-архитектура-системы)
2. [Компоненты и связи](#2-компоненты-и-связи)
3. [Паттерны интеграции](#3-паттерны-интеграции)
4. [Best Practices](#4-best-practices)
5. [Troubleshooting](#5-troubleshooting)

---

## 1. Архитектура системы

### 1.1. Обзор архитектуры

Qwen Code Orchestrator Kit построен по модульной архитектуре с четким разделением ответственности между компонентами:

```
┌─────────────────────────────────────────────────────────────────┐
│                     QWEN CODE ORCHESTRATOR KIT                   │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │                    ОРКЕСТРАТОРЫ (7)                       │   │
│  │  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐         │   │
│  │  │  Planning   │ │    Dev      │ │   Testing   │         │   │
│  │  │  Analyzer   │ │ Coordinator │ │  Assurer    │         │   │
│  │  └─────────────┘ └─────────────┘ └─────────────┘         │   │
│  │  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐         │   │
│  │  │  Backend    │ │  Frontend   │ │  Security   │         │   │
│  │  │ Coordinator │ │ Coordinator │ │Orchestrator │         │   │
│  │  └─────────────┘ └─────────────┘ └─────────────┘         │   │
│  └──────────────────────────────────────────────────────────┘   │
│                              │                                   │
│                              ▼                                   │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │                     ВОРКЕРЫ (18)                          │   │
│  │  Code Analysis │ Dependency │ Test Generation │ ...       │   │
│  └──────────────────────────────────────────────────────────┘   │
│                              │                                   │
│                              ▼                                   │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │                     НАВЫКИ (36)                           │   │
│  │  Validation │ Quality Gates │ Reports │ Security │ ...    │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │                    СКРИПТЫ (50+)                          │   │
│  │  Git │ Quality Gates │ Orchestration │ Release │ ...      │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### 1.2. Уровни абстракции

| Уровень | Компоненты | Назначение |
|---------|------------|------------|
| **Оркестрация** | Оркестраторы | Координация многошаговых задач |
| **Исполнение** | Воркеры | Выполнение конкретных задач |
| **Утилиты** | Навыки | Вспомогательные функции |
| **Автоматизация** | Скрипты | Автоматизация процессов |

### 1.3. Поток данных

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│   Специфика- │     │    План      │     │   Выполнение │
│    ция       │────▶│   выполнения │────▶│   задач      │
└──────────────┘     └──────────────┘     └──────────────┘
                            │                    │
                            ▼                    ▼
                     ┌──────────────┐     ┌──────────────┐
                     │   Отчеты     │◀────│  Верификация │
                     └──────────────┘     └──────────────┘
```

---

## 2. Компоненты и связи

### 2.1. Оркестраторы

| Компонент | Назначение | Домен |
|-----------|------------|-------|
| `orc_planning_task_analyzer` | Анализ и планирование задач | planning |
| `orc_dev_task_coordinator` | Координация разработки | dev |
| `orc_backend_api_coordinator` | Координация backend разработки | backend |
| `orc_frontend_ui_coordinator` | Координация frontend разработки | frontend |
| `orc_testing_quality_assurer` | Обеспечение качества тестирования | testing |
| `orc_security_security_orchestrator` | Координация безопасности | security |
| `orc_research_data_analyzer` | Анализ данных исследований | research |

### 2.2. Воркеры

#### Разработка
- `work_dev_code_analyzer` - Анализ кода
- `work_dev_dependency_analyzer` - Анализ зависимостей
- `work_dev_meta_agent` - Мета-агент разработки
- `work_dev_qwen_code_cli_specialist` - CLI специалист

#### Backend
- `work_backend_api_validator` - Валидация API

#### Frontend
- `work_frontend_component_generator` - Генерация компонентов

#### Тестирование
- `work_testing_code_quality_checker` - Проверка качества кода
- `work_testing_test_generator` - Генерация тестов

#### Безопасность
- `work_security_security_analyzer` - Анализ безопасности

#### Здоровье кода
- `work_health_bug_fixer` - Исправление ошибок
- `work_health_bug_hunter` - Поиск ошибок
- `work_health_dead_code_detector` - Детектор мертвого кода

#### Планирование
- `work_planning_agent_requirer` - Требования агентов
- `work_planning_executor_assigner` - Назначение исполнителей
- `work_planning_task_classifier` - Классификация задач

#### Документирование
- `work_doc_tech_translator_ru` - Технический перевод

#### Мета
- `work_meta_agent_creator` - Создание агентов

#### Исследования
- `work_research_trend_tracker` - Трекер трендов

### 2.3. Навыки

| Категория | Навыки |
|-----------|--------|
| **Валидация** | `validate-plan-file`, `validate-report-file`, `yaml-header-validator` |
| **Качество** | `code-quality-checker`, `run-quality-gate`, `agent-structure-checker` |
| **Безопасность** | `security-analyzer`, `security-scanner` |
| **Отчеты** | `generate-report-header`, `generate-changelog`, `format-markdown-table` |
| **Анализ** | `parse-error-logs`, `parse-git-status`, `extract-version` |
| **Рефакторинг** | `code-refactorer`, `code-cleaner`, `bug-fixer`, `bug-hunter` |
| **Зависимости** | `dependency-auditor`, `dependency-validation` |
| **Сессии** | `save-session-context`, `resume-session`, `graceful-shutdown` |
| **Прогресс** | `progress-logging`, `calculate-priority-score` |
| **Документация** | `documentation-generator`, `tech-translator-ru` |
| **MCP** | `select-mcp-server`, `external-api-mocking` |
| **Уведомления** | `webhook-sender` |
| **Спецификации** | `specification-analyzer`, `task-analyzer` |
| **Шаблоны** | `skill-template`, `check-agent-name-uniqueness` |

### 2.4. Карта связей

```
                    ┌─────────────────────────┐
                    │  orc_planning_task_     │
                    │       analyzer          │
                    └───────────┬─────────────┘
                                │
        ┌───────────────────────┼───────────────────────┐
        │                       │                       │
        ▼                       ▼                       ▼
┌───────────────┐     ┌───────────────┐     ┌───────────────┐
│    orc_dev    │     │  orc_testing  │     │  orc_security │
│  task_        │     │  quality_     │     │  security_    │
│  coordinator  │     │  assurer      │     │  orchestrator │
└───────┬───────┘     └───────┬───────┘     └───────┬───────┘
        │                     │                     │
        ▼                     ▼                     ▼
┌───────────────┐     ┌───────────────┐     ┌───────────────┐
│ work_dev_*    │     │work_testing_* │     │work_security_*│
│ work_backend_*│     │               │     │               │
│ work_frontend_*│    │               │     │               │
└───────────────┘     └───────────────┘     └───────────────┘
```

---

## 3. Паттерны интеграции

### 3.1. Последовательная интеграция

Используется для многофазных рабочих процессов:

```bash
# Пример: Полный цикл разработки
.qwen/scripts/pipelines/full-dev-pipeline.sh SPEC-001

# Этапы:
# 1. Planning (orc_planning_task_analyzer)
# 2. Development (orc_dev_task_coordinator)
# 3. Testing (orc_testing_quality_assurer)
# 4. Security (orc_security_security_orchestrator)
```

### 3.2. Параллельная интеграция

Используется для независимых компонентов:

```bash
# Пример: Параллельная разработка backend и frontend
orc_backend_api_coordinator --spec SPEC-001 &
orc_frontend_ui_coordinator --spec SPEC-001 &
wait
```

### 3.3. Интеграция через артефакты

Компоненты обмениваются данными через файлы:

```
specs/
└── SPEC-001/
    ├── plans/
    │   ├── phase0-plan.json
    │   └── phase0-assignments.json
    ├── reports/
    │   ├── planning-report.md
    │   ├── development-report.md
    │   └── testing-report.md
    └── summary.md
```

### 3.4. Интеграция через навыки

Оркестраторы используют навыки для общих операций:

```yaml
# Пример использования навыков в оркестраторе
tools:
  - skill: validate-plan-file
  - skill: run-quality-gate
  - skill: generate-report-header
```

---

## 4. Best Practices

### 4.1. Принципы интеграции

#### ✅ Делайте:

1. **Явные контракты**
   - Четко определяйте входные и выходные артефакты
   - Документируйте форматы данных
   - Используйте валидацию схем

2. **Изоляция компонентов**
   - Минимизируйте прямые зависимости
   - Используйте файловую передачу данных
   - Избегайте глобального состояния

3. **Обработка ошибок**
   - Реализуйте graceful degradation
   - Логируйте все ошибки
   - Предоставляйте fallback сценарии

4. **Тестирование**
   - Пишите интеграционные тесты
   - Тестируйте сценарии ошибок
   - Автоматизируйте проверку интеграции

#### ❌ Не делайте:

1. **Жесткие зависимости**
   - Не создавайте циклических зависимостей
   - Избегайте импортов компонентов напрямую
   - Не полагайтесь на порядок инициализации

2. **Глобальное состояние**
   - Не используйте общие переменные
   - Избегайте модификации чужих артефактов
   - Не храните состояние вне артефактов

3. **Игнорирование ошибок**
   - Не игнорируйте коды возврата
   - Не скрывайте ошибки от пользователя
   - Не продолжайте выполнение после критических ошибок

### 4.2. Управление версиями

```
┌─────────────────────────────────────────┐
│         Version Compatibility           │
├─────────────────────────────────────────┤
│ Major.Minor.Patch                       │
│   │      │      │                       │
│   │      │      └─ Backward compatible  │
│   │      └─ New features (compatible)   │
│   └─ Breaking changes                   │
└─────────────────────────────────────────┘
```

### 4.3. Логирование

Стандартный формат логов:

```
[TIMESTAMP] [LEVEL] [COMPONENT] [PHASE] MESSAGE

# Примеры
[2026-03-21T10:30:00.000Z] [INFO] [orc_dev_task_coordinator] [INIT] Starting orchestration
[2026-03-21T10:30:01.000Z] [ERROR] [orc_dev_task_coordinator] [QGate] Quality gate failed
```

### 4.4. Мониторинг

Ключевые метрики для мониторинга:

| Метрика | Описание | Порог |
|---------|----------|-------|
| `orchestration.duration` | Длительность оркестрации | < 10 мин |
| `orchestration.success_rate` | Процент успешных выполнений | > 95% |
| `quality_gate.pass_rate` | Процент проходящих Quality Gate | > 90% |
| `error.rate` | Частота ошибок | < 5% |

---

## 5. Troubleshooting

### 5.1. Общие проблемы

#### Проблема: Оркестратор не видит воркера

**Симптомы:**
```
ERROR: Worker 'work_dev_code_analyzer' not found
```

**Решение:**
1. Проверьте существование файла воркера:
   ```bash
   ls -la .qwen/agents/work_dev_code_analyzer.md
   ```
2. Проверьте YAML заголовок воркера:
   ```bash
   head -20 .qwen/agents/work_dev_code_analyzer.md
   ```
3. Запустите компонент реестр:
   ```bash
   .qwen/integration/component-registry.sh --verbose
   ```

#### Проблема: Quality Gate не проходит

**Симптомы:**
```
ERROR: Quality gate failed: type-check
```

**Решение:**
1. Проверьте логи Quality Gate:
   ```bash
   cat .qwen/logs/quality-gate.log
   ```
2. Запустите проверку вручную:
   ```bash
   .qwen/scripts/quality-gates/check-type-check.sh
   ```
3. Исправьте ошибки типов и повторите

#### Проблема: Отсутствуют артефакты

**Симптомы:**
```
ERROR: Artifact not found: specs/SPEC-001/plans/phase0-plan.json
```

**Решение:**
1. Проверьте что предыдущая фаза завершилась успешно
2. Проверьте права доступа к директории:
   ```bash
   ls -la specs/SPEC-001/plans/
   ```
3. Запустите предыдущую фазу заново

### 5.2. Диагностика интеграции

#### Использование Component Registry

```bash
# Получить обзор всех компонентов
.qwen/integration/component-registry.sh

# Подробный вывод в Markdown
.qwen/integration/component-registry.sh --markdown --verbose

# Сохранить в файл
.qwen/integration/component-registry.sh --output registry.md --markdown
```

#### Использование Integration Test Runner

```bash
# Запуск всех тестов
.qwen/integration/integration-test-runner.sh

# Запуск конкретного теста
.qwen/integration/integration-test-runner.sh --test feedback-analytics

# С генерацией отчета
.qwen/integration/integration-test-runner.sh --report
```

#### Использование Component Linker

```bash
# Анализ зависимостей
.qwen/integration/component-linker.sh --analyze --verbose

# Поиск отсутствующих связей
.qwen/integration/component-linker.sh --find-missing

# Генерация рекомендаций
.qwen/integration/component-linker.sh --recommend
```

### 5.3. Восстановление после ошибок

#### Graceful Shutdown

При timeout или ошибке система автоматически сохраняет состояние:

```bash
# Проверка сохраненных состояний
ls -la .qwen/state/

# Восстановление сессии
.qwen/scripts/orchestration-tools/resume-session.sh <session-id>
```

#### Откат изменений

```bash
# Откат последних изменений
.qwen/scripts/git/rollback.sh

# Откат к конкретному тегу
.qwen/scripts/git/rollback.sh --to v0.5.0
```

### 5.4. Полезные команды

```bash
# Проверка структуры проекта
tree -L 3 .qwen/

# Поиск компонентов по имени
find .qwen/ -name "*component*" -type f

# Проверка синтаксиса YAML заголовков
.qwen/scripts/validation/validate-yaml-headers.sh

# Генерация отчета о состоянии
.qwen/scripts/monitoring/generate-status-report.sh
```

---

## Приложение A: Быстрый старт

### A.1. Установка и настройка

```bash
# 1. Клонирование репозитория
git clone <repository-url>
cd qwen_orc_kit_ru

# 2. Установка зависимостей
npm install

# 3. Проверка установки
.qwen/integration/component-registry.sh

# 4. Запуск интеграционных тестов
.qwen/integration/integration-test-runner.sh
```

### A.2. Первый запуск

```bash
# 1. Создание спецификации
mkdir -p specs/SPEC-001
echo "# Моя спецификация" > specs/SPEC-001/spec.md

# 2. Запуск планирования
orc_planning_task_analyzer --spec SPEC-001

# 3. Проверка результатов
cat specs/SPEC-001/plans/phase0-plan.json
```

---

## Приложение B: Ссылки

- [Стандарт оркестрации](../standards/orchestration-standard.md)
- [Стандарт взаимодействия оркестраторов](../standards/cross-orchestrator-communication.md)
- [Реестр компонентов](../integration/component-registry.sh)
- [Тесты интеграции](../integration/integration-test-runner.sh)

---

**Документ утвержден:** Qwen Code Orchestrator Kit Team  
**Дата утверждения:** 21 марта 2026  
**Следующий пересмотр:** 21 июня 2026
