# SpecKit Руководство

**Версия:** 1.0.0
**Дата:** 2026-03-21
**Статус:** Active

---

## Содержание

1. [Обзор](#1-обзор)
2. [Архитектура](#2-архитектура)
3. [Команды](#3-команды)
4. [Скрипты](#4-скрипты)
5. [Шаблоны](#5-шаблоны)
6. [Workflow](#6-workflow)
7. [Executor Assignment](#7-executor-assignment)
8. [Примеры использования](#8-примеры-использования)
9. [Troubleshooting](#9-troubleshooting)

---

## 1. Обзор

### 1.1 Что такое SpecKit?

**SpecKit** (Specification-driven Development Toolkit) — это набор инструментов для specification-driven разработки, обеспечивающий полный цикл от анализа требований до создания GitHub issues.

### 1.2 Преимущества

- ✅ **Структурированный подход** — Четкий workflow из 9 шагов
- ✅ **Автоматизация** — Скрипты для каждой команды
- ✅ **Шаблоны** — Готовые шаблоны документов
- ✅ **Traceability** — Полная прослеживаемость требований
- ✅ **Интеграция** — GitHub Issues интеграция

### 1.3 Компоненты SpecKit

```
SpecKit
├── Commands (9 команд)
│   ├── speckit.analyze
│   ├── speckit.specify
│   ├── speckit.clarify
│   ├── speckit.plan
│   ├── speckit.implement
│   ├── speckit.checklist
│   ├── speckit.tasks
│   ├── speckit.constitution
│   └── speckit.taskstoissues
├── Scripts (9 скриптов)
├── Templates (4 шаблона)
└── Documentation
```

---

## 2. Архитектура

### 2.1 Структура директорий

```
.qwen/
├── commands/
│   ├── speckit.analyze.md
│   ├── speckit.specify.md
│   ├── speckit.clarify.md
│   ├── speckit.plan.md
│   ├── speckit.implement.md
│   ├── speckit.checklist.md
│   ├── speckit.tasks.md
│   ├── speckit.constitution.md
│   └── speckit.taskstoissues.md
├── specify/
│   ├── scripts/
│   │   ├── analyze.sh
│   │   ├── specify.sh
│   │   ├── clarify.sh
│   │   ├── plan.sh
│   │   ├── implement.sh
│   │   ├── checklist.sh
│   │   ├── tasks.sh
│   │   ├── constitution.sh
│   │   └── taskstoissues.sh
│   └── templates/
│       ├── spec-template.md
│       ├── plan-template.md
│       ├── task-template.md
│       └── constitution-template.md
└── docs/
    └── speckit-guide.md
```

### 2.2 Структура спецификаций

```
specs/
└── {SPEC_ID}/
    ├── state.json              # Состояние workflow
    ├── requirements.md         # Требования
    ├── spec.md                 # Спецификация
    ├── plan.md                 # План реализации
    ├── tasks.md                # Задачи
    ├── constitution.md         # Конституция проекта
    ├── checklist.md            # Чек-лист приемки
    ├── traceability-matrix.md  # Матрица traceability
    ├── phase-reports/          # Отчеты по фазам
    └── memory/                 # Память спецификации
```

---

## 3. Команды

### 3.1 speckit.analyze

**Назначение:** Анализ требований пользователя

**Использование:**
```bash
/qwen speckit.analyze
```

**Выходные артефакты:**
- `specs/{ID}/requirements.md` — Документ требований
- `specs/{ID}/analysis-report.md` — Отчет об анализе
- `specs/{ID}/questions.md` — Список вопросов

**Пример:**
```markdown
# Requirements Analysis Report

**Статус:** ✅ Завершено
**Полнота:** 75%

## Собранные требования
- Функциональные: 15 требований
- Нефункциональные: 8 требований
```

---

### 3.2 speckit.specify

**Назначение:** Создание спецификации проекта

**Использование:**
```bash
/qwen speckit.specify
```

**Выходные артефакты:**
- `specs/{ID}/spec.md` — Основная спецификация
- `specs/{ID}/spec-summary.md` — Краткое резюме
- `specs/{ID}/glossary.md` — Глоссарий

**9 обязательных разделов:**
1. Обзор проекта
2. Функциональные требования
3. Нефункциональные требования
4. Ограничения
5. Предположения
6. Критерии успеха
7. Архитектурные решения
8. Интерфейсы
9. Риски

---

### 3.3 speckit.clarify

**Назначение:** Уточнение спецификации

**Использование:**
```bash
/qwen speckit.clarify
```

**Выходные артефакты:**
- `specs/{ID}/clarification-questions.md` — Вопросы
- `specs/{ID}/clarification-answers.md` — Ответы
- `specs/{ID}/spec-changelog.md` — История изменений

---

### 3.4 speckit.plan

**Назначение:** Планирование реализации

**Использование:**
```bash
/qwen speckit.plan
```

**Выходные артефакты:**
- `specs/{ID}/plan.md` — План реализации
- `specs/{ID}/timeline.md` — Временная шкала
- `specs/{ID}/dependencies.md` — Матрица зависимостей

**Фазы:**
- Фаза 0: Подготовка
- Фаза 1: Инфраструктура
- Фаза 2: Основные функции
- Фаза 3: Интеграции
- Фаза 4: Тестирование
- Фаза 5: Документирование
- Фаза 6: Релиз

---

### 3.5 speckit.implement

**Назначение:** Реализация проекта

**Использование:**
```bash
/qwen speckit.implement
```

**Выходные артефакты:**
- `specs/{ID}/implementation-log.md` — Лог выполнения
- `specs/{ID}/phase-reports/` — Отчеты по фазам
- `specs/{ID}/implementation-summary.md` — Итоговое резюме

**Агенты:**
- `work_dev_specialist` — Разработка
- `work_test_specialist` — Тестирование
- `work_doc_writer` — Документирование

---

### 3.6 speckit.checklist

**Назначение:** Создание чек-листа приемки

**Использование:**
```bash
/qwen speckit.checklist
```

**Выходные артефакты:**
- `specs/{ID}/checklist.md` — Чек-лист
- `specs/{ID}/acceptance-tests.md` — Acceptance тесты
- `specs/{ID}/acceptance-criteria.md` — Критерии приемки

---

### 3.7 speckit.tasks

**Назначение:** Генерация задач

**Использование:**
```bash
/qwen speckit.tasks
```

**Выходные артефакты:**
- `specs/{ID}/tasks.md` — Задачи
- `specs/{ID}/traceability-matrix.md` — Матрица traceability
- `specs/{ID}/agent-assignments.md` — Назначения агентов
- `specs/{ID}/priority-board.md` — Доска приоритетов

---

### 3.8 speckit.constitution

**Назначение:** Создание конституции проекта

**Использование:**
```bash
/qwen speckit.constitution
```

**Выходные артефакты:**
- `specs/{ID}/constitution.md` — Конституция
- `specs/{ID}/coding-standards.md` — Стандарты кода
- `specs/{ID}/architecture-rules.md` — Архитектурные правила
- `specs/{ID}/review-checklist.md` — Чек-лист ревью

---

### 3.9 speckit.taskstoissues

**Назначение:** Конвертация задач в GitHub Issues

**Использование:**
```bash
/qwen speckit.taskstoissues
```

**Требования:**
```bash
export GITHUB_TOKEN=ghp_xxxxxxxxxxxxxxxxxxxx
export GITHUB_OWNER=username
export GITHUB_REPO=repository
```

**Выходные артефакты:**
- `specs/{ID}/issues-log.md` — Лог создания issues
- `specs/{ID}/github-links.md` — Ссылки на issues

---

## 4. Скрипты

### 4.1 Запуск скриптов

```bash
# Прямой запуск
.qwen/specify/scripts/analyze.sh [SPEC_ID]

# Через команду Qwen
/qwen speckit.analyze
```

### 4.2 Параметры скриптов

| Скрипт | Параметры | Описание |
|--------|-----------|----------|
| analyze.sh | [SPEC_ID] | ID спецификации (автогенерация если не указан) |
| specify.sh | [SPEC_ID] [PROJECT_NAME] | ID и имя проекта |
| clarify.sh | [SPEC_ID] | ID спецификации |
| plan.sh | [SPEC_ID] [PROJECT_NAME] | ID и имя проекта |
| implement.sh | [SPEC_ID] [PROJECT_NAME] [PHASE] | ID, имя, фаза (all/0-6) |
| checklist.sh | [SPEC_ID] [PROJECT_NAME] | ID и имя проекта |
| tasks.sh | [SPEC_ID] [PROJECT_NAME] | ID и имя проекта |
| constitution.sh | [SPEC_ID] [PROJECT_NAME] | ID и имя проекта |
| taskstoissues.sh | [SPEC_ID] [DRY_RUN] | ID и режим (true/false) |

### 4.3 Переменные окружения

```bash
# Для taskstoissues.sh
export GITHUB_TOKEN=ghp_xxxxxxxxxxxxxxxxxxxx
export GITHUB_OWNER=username
export GITHUB_REPO=repository

# Опционально
export SPEC_ID=SPEC-20260321-120000
export PROJECT_NAME="My Project"
```

---

## 5. Шаблоны

### 5.1 spec-template.md

Шаблон спецификации проекта с 9 обязательными разделами.

**Использование:**
```bash
cp .qwen/specify/templates/spec-template.md specs/{ID}/spec.md
# Заполнить плейсхолдеры {{PROJECT_NAME}}, {{SPEC_ID}}, etc.
```

### 5.2 plan-template.md

Шаблон плана реализации с фазами и задачами.

### 5.3 task-template.md

Шаблон документа задач с матрицей traceability.

### 5.4 constitution-template.md

Шаблон конституции проекта со стандартами и правилами.

---

## 6. Workflow

### 6.1 Полный workflow

```
┌─────────────────────────────────────────────────────────────┐
│                    SpecKit Workflow                         │
└─────────────────────────────────────────────────────────────┘

    ┌──────────────┐
    │    START     │
    └──────┬───────┘
           │
           ▼
    ┌──────────────┐
    │  1. Analyze  │ ──→ requirements.md
    └──────┬───────┘
           │
           ▼
    ┌──────────────┐
    │  2. Specify  │ ──→ spec.md
    └──────┬───────┘
           │
           ▼
    ┌──────────────┐
    │  3. Clarify  │ ──→ clarification-*.md
    └──────┬───────┘
           │
           ▼
    ┌──────────────┐
    │   4. Plan    │ ──→ plan.md, timeline.md
    └──────┬───────┘
           │
           ▼
    ┌──────────────┐
    │ 5. Implement │ ──→ implementation-*.md
    └──────┬───────┘
           │
           ▼
    ┌──────────────┐
    │ 6. Checklist │ ──→ checklist.md
    └──────┬───────┘
           │
           ▼
    ┌──────────────┐
    │   7. Tasks   │ ──→ tasks.md, traceability.md
    └──────┬───────┘
           │
           ▼
    ┌──────────────┐
    │  8. Consti-  │ ──→ constitution.md
    │   tution     │
    └──────┬───────┘
           │
           ▼
    ┌──────────────┐
    │ 9. TasksTo-  │ ──→ GitHub Issues
    │   Issues     │
    └──────┬───────┘
           │
           ▼
    ┌──────────────┐
    │     END      │
    └──────────────┘
```

### 6.2 Состояния workflow

```json
{
  "id": "SPEC-20260321-120000",
  "created": "2026-03-21T12:00:00Z",
  "phase": "analyze",
  "status": "in_progress",
  "commands": {
    "analyze": "completed",
    "specify": "not_started",
    "clarify": "not_started",
    "plan": "not_started",
    "implement": "not_started",
    "checklist": "not_started",
    "tasks": "not_started",
    "constitution": "not_started",
    "taskstoissues": "not_started"
  }
}
```

### 6.3 Валидация между шагами

| Переход | Проверка |
|---------|----------|
| analyze → specify | requirements.md существует |
| specify → clarify | spec.md существует |
| clarify → plan | spec.md обновлен |
| plan → implement | plan.md существует |
| implement → checklist | implementation-summary.md существует |
| checklist → tasks | checklist.md существует |
| tasks → constitution | tasks.md существует |
| constitution → taskstoissues | constitution.md существует |

---

## 7. Executor Assignment

### 7.1 Агенты SpecKit

| Агент | Роль | Команды |
|-------|------|---------|
| `spec_analyzer` | Анализ требований | speckit.analyze |
| `spec_writer` | Написание спецификаций | speckit.specify, speckit.clarify |
| `spec_planner` | Планирование | speckit.plan |
| `orchestrator` | Оркестрация | speckit.implement |
| `qa_specialist` | Контроль качества | speckit.checklist |
| `task_manager` | Управление задачами | speckit.tasks |
| `architect` | Архитектура | speckit.constitution |
| `integration_bot` | GitHub интеграция | speckit.taskstoissues |

### 7.2 Назначение исполнителей

```json
{
  "phase": 1,
  "command": "speckit.analyze",
  "agent": "spec_analyzer",
  "backup": "spec_writer",
  "timeout": 300,
  "retry": 3
}
```

### 7.3 Конфигурация оркестратора

```json
{
  "orchestrator": "orc_spec_kit",
  "workflow": "speckit",
  "agents": {
    "analyze": "spec_analyzer",
    "specify": "spec_writer",
    "clarify": "spec_writer",
    "plan": "spec_planner",
    "implement": "orchestrator",
    "checklist": "qa_specialist",
    "tasks": "task_manager",
    "constitution": "architect",
    "taskstoissues": "integration_bot"
  }
}
```

---

## 8. Примеры использования

### 8.1 Быстрый старт

```bash
# 1. Инициализация спецификации
/qwen speckit.analyze

# 2. Создание спецификации
/qwen speckit.specify

# 3. Уточнение деталей
/qwen speckit.clarify

# 4. Планирование
/qwen speckit.plan

# 5. Реализация
/qwen speckit.implement

# 6. Приемка
/qwen speckit.checklist

# 7. Задачи
/qwen speckit.tasks

# 8. Конституция
/qwen speckit.constitution

# 9. GitHub Issues
/qwen speckit.taskstoissues
```

### 8.2 Пример с параметрами

```bash
# Запуск с конкретным SPEC_ID
.qwen/specify/scripts/analyze.sh SPEC-20260321-001

# Запуск plan с именем проекта
.qwen/specify/scripts/plan.sh SPEC-20260321-001 "My Project"

# Запуск implement для конкретной фазы
.qwen/specify/scripts/implement.sh SPEC-20260321-001 "My Project" 2

# Dry run для taskstoissues
.qwen/specify/scripts/taskstoissues.sh SPEC-20260321-001 true
```

### 8.3 Интеграция с GitHub

```bash
# Настройка переменных окружения
export GITHUB_TOKEN=ghp_xxxxxxxxxxxxxxxxxxxx
export GITHUB_OWNER=myusername
export GITHUB_REPO=myrepo

# Создание issues
/qwen speckit.taskstoissues
```

---

## 9. Troubleshooting

### 9.1 Частые проблемы

#### Проблема: SPEC_ID не найден

**Решение:**
```bash
# Проверить существующие спецификации
ls specs/

# Или указать SPEC_ID явно
.qwen/specify/scripts/analyze.sh SPEC-NEW-ID
```

#### Проблема: jq не найден

**Решение:**
```bash
# Ubuntu/Debian
sudo apt-get install jq

# macOS
brew install jq

# Или использовать режим без jq (ограниченная функциональность)
```

#### Проблема: GitHub API ошибка

**Решение:**
```bash
# Проверить токен
echo $GITHUB_TOKEN

# Проверить права токена
# Токен должен иметь права: repo, workflow

# Использовать dry run
.qwen/specify/scripts/taskstoissues.sh SPEC-ID true
```

#### Проблема: Шаблон не найден

**Решение:**
```bash
# Проверить наличие шаблонов
ls .qwen/specify/templates/

# Создать директорию если отсутствует
mkdir -p .qwen/specify/templates
```

### 9.2 Логирование

```bash
# Просмотр логов
cat .qwen/logs/speckit-*.log

# Включить подробное логирование
export SPECKIT_DEBUG=true
```

### 9.3 Восстановление состояния

```bash
# Сброс состояния спецификации
rm specs/{SPEC_ID}/state.json

# Запуск с начала
/qwen speckit.analyze
```

---

## Приложения

### A. Чек-лист SpecKit

- [ ] 9 команд созданы
- [ ] 9 скриптов работают
- [ ] 4 шаблона готовы
- [ ] Документация полная
- [ ] Executor assignment настроен

### B. Ссылки

- [SpecKit Commands](../commands/)
- [SpecKit Scripts](../specify/scripts/)
- [SpecKit Templates](../specify/templates/)

### C. История изменений

| Версия | Дата | Изменения |
|--------|------|-----------|
| 1.0.0 | 2026-03-21 | Initial version |
