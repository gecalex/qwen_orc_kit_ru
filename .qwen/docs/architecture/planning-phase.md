# Фаза планирования (Phase 0)

## Обзор

Фаза планирования (Phase 0) - это автоматизированный этап в процессе разработки, который выполняется перед основной реализацией. Она предназначена для анализа задач, определения требуемых типов агентов, назначения исполнителей и создания плана выполнения.

## Назначение

- Анализ задач и определение требуемых типов агентов
- Назначение исполнителей для каждой задачи
- Создание плана выполнения в формате JSON
- Проверка наличия необходимых агентов и инициирование создания отсутствующих
- Включение рекомендаций по использованию MCP серверов для различных задач
- Интеграция с Quality Gate 1 (Planning Quality Gate)

## Компоненты фазы планирования

### Оркестратор анализа задач (`orc_planning_task_analyzer`)

Координация процесса анализа задач, определение требуемых агентов, назначение исполнителей и создание плана выполнения.

### Воркеры фазы планирования

- `work_planning_task_classifier` - анализирует и классифицирует задачи
- `work_planning_agent_requirer` - определяет необходимые типы агентов
- `work_planning_executor_assigner` - назначает исполнителей для задач

### Скрипты

- `.qwen/specify/scripts/phase0-analyzer.sh` - автоматизирует анализ задач
- `.qwen/scripts/quality-gates/check-planning.sh` - Quality Gate 1

### Схемы

- `state/planning-phase.schema.json` - определяет структуру плана фазы планирования

## Процесс выполнения

### 0. Инициализация

Запустить анализ Фазы 0:
```bash
.qwen/specify/scripts/phase0-analyzer.sh .qwen/specify/specs/{ID}-{feature}
```

### 1. Анализ задач

Оркестратор читает спецификацию и анализирует задачи из:
- `.qwen/specify/specs/{ID}/spec.md`
- `.qwen/specify/specs/{ID}/tasks.md`

### 2. Классификация

Воркер классифицирует задачи по типам и сложности:
- Backend задачи
- Frontend задачи
- Testing задачи
- Documentation задачи

### 3. Определение агентов

Воркер определяет, какие типы агентов требуются:
- Оркестраторы: `orc_*`
- Воркеры: `work_*`

### 4. Назначение исполнителей

Воркер назначает подходящих исполнителей:
- Проверка наличия агентов в `.qwen/agents/`
- Создание задач для отсутствующих агентов

### 5. Создание плана

Создается файл плана в формате JSON:
- `.qwen/specify/specs/{ID}/plans/phase0-plan.json`
- `.qwen/specify/specs/{ID}/plans/phase0-agents.json`
- `.qwen/specify/specs/{ID}/plans/phase0-assignments.json`

### 6. Проверка (Quality Gate 1)

Запускается Quality Gate 1:
```bash
.qwen/scripts/quality-gates/check-planning.sh .qwen/specify/specs/{ID}
```

**Проверки:**
- ✅ План Фазы 0 существует
- ✅ Назначения агентов существуют
- ✅ tasks.md существует
- ✅ plan.md существует
- ✅ spec.md существует

### 7. Создание отсутствующих агентов

При необходимости запускается процесс создания новых агентов через `work_dev_meta_agent`.

## Формат плана фазы 0

План фазы 0 создается в формате JSON и соответствует схеме `state/planning-phase.schema.json`.

**Расположение:** `.qwen/specify/specs/{ID}/plans/phase0-plan.json`

Пример:

```json
{
  "phase": 0,
  "specification": ".qwen/specify/specs/001-user-auth/spec.md",
  "createdAt": "2026-03-18T12:00:00Z",
  "status": "initialized",
  "config": {
    "priority": "high",
    "scope": [".qwen/specify/specs/001-user-auth"],
    "estimatedTasks": 10
  },
  "validation": {
    "required": ["task-analysis", "agent-determination"],
    "optional": ["mcp-recommendations"]
  },
  "mcpGuidance": {
    "recommended": ["mcp__context7__*", "mcp__filesystem__*", "mcp__git__*"],
    "library": "planning",
    "reason": "Проверка текущих шаблонов планирования"
  },
  "nextAgent": "orc_planning_task_analyzer",
  "gates": {
    "gate0": {
      "name": "Pre-Planning Gate",
      "status": "pending",
      "script": ".qwen/scripts/quality-gates/check-planning.sh"
    },
    "gate1": {
      "name": "Planning Quality Gate",
      "status": "pending",
      "script": ".qwen/scripts/quality-gates/check-planning.sh"
    }
  }
}
```

## Интеграция с Speckit

### speckit.plan

Инициализирует Фазу 0:
```bash
.qwen/specify/scripts/phase0-analyzer.sh .qwen/specify/specs/{ID}-{feature}
```

### speckit.tasks

Использует результаты Фазы 0:
- Читает `phase0-assignments.json`
- Использует назначения агентов для генерации задач

### speckit.implement

Проверяет завершение Фазы 0:
```bash
.qwen/scripts/quality-gates/check-planning.sh .qwen/specify/specs/{ID}
```

Только после успешной проверки переходит к реализации.

## Интеграция с MCP

Фаза планирования включает рекомендации по использованию MCP серверов, которые передаются воркерам через поле `mcpGuidance` в плановом файле.

**Рекомендуемые MCP серверы:**
- `mcp__context7__*` — документация API
- `mcp__filesystem__*` — работа с файлами
- `mcp__git__*` — Git операции

## Стандартизированные отчеты

Все агенты фазы планирования генерируют отчеты в стандартизированном формате, который включает:

- Заголовок с метаданными
- Исполнительное резюме
- Выполненная работа
- Внесенные изменения
- Результаты валидации
- Метрики выполнения
- Обнаруженные ошибки
- Следующие шаги
- Артефакты выполнения

## Quality Gate 1

**Скрипт:** `.qwen/scripts/quality-gates/check-planning.sh`

**Проверки:**
1. ✅ План Фазы 0 существует
2. ✅ Назначения агентов существуют
3. ✅ tasks.md существует
4. ✅ plan.md существует
5. ✅ spec.md существует

**Блокирующая:** true (останавливает процесс при неудаче)

**При неудаче:**
- ОСТАНОВКА процесса
- Откат изменений
- Выход с ошибкой