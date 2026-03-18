# 📊 ОТЧЕТ: АНАЛИЗ ФАЗЫ 0 (PHASE 0) В КОНТЕКСТЕ НОВЫХ ИЗМЕНЕНИЙ

**Дата:** 18 марта 2026  
**Ветка:** `research/specification-standards-2026`  
**Цель:** Анализ реализации Фазы 0 и интеграция с `.qwen/specify/`

---

## 1. ТЕКУЩАЯ РЕАЛИЗАЦИЯ ФАЗЫ 0

### 1.1. Компоненты

**Оркестратор:**
```
.qwen/agents/orc_planning_task_analyzer.md
```

**Воркеры:**
```
.qwen/agents/work_planning_task_classifier.md
.qwen/agents/work_planning_agent_requirer.md
.qwen/agents/work_planning_executor_assigner.md
```

**Скрипты:**
```
.qwen/scripts/orchestration-tools/phase0-analyzer.sh
```

**Схемы:**
```
state/planning-phase.schema.json
```

**Документация:**
```
.qwen/docs/architecture/planning-phase.md
```

---

### 1.2. Процесс Фазы 0

**Текущий процесс (из orc_planning_task_analyzer.md):**

```
1. Фаза 0: Анализ планирования
   - Анализ задач из спецификации
   - Определение требуемых типов агентов
   - Определение отсутствующих агентов
   - Создание плана в .tmp/current/plans/planning-phase-plan.json

2. Фаза 1: Назначение исполнителей
   - Назначение исполнителей для каждой задачи
   - Проверка соответствия агентов
   - Создание задач для meta-agent-v3

3. Фаза 2-N: Выполнение подфаз
   - Создание файла плана
   - Включение рекомендаций MCP
   - Проверка плана (validate-plan-file)
   - Сигнал готовности

4. Контрольная точка качества
   - Проверка отчета работника
   - Запуск quality gates
   - Блокировка при неудаче

5. Финальная фаза: Резюме
   - Сбор отчетов
   - Расчет метрик
   - Генерация резюме
   - Создание tasks.md в specs/[feature]/
```

---

### 1.3. Анализ скрипта phase0-analyzer.sh

**Текущая функциональность:**

```bash
#!/bin/bash
# Проверка спецификации
if [ ! -f "specs/current/spec.md" ]; then
  echo "❌ ОШИБКА: Файл спецификации не найден"
  exit 1
fi

# Анализ задач
TASK_COUNT=$(grep -c "^\*\*Требования\*\*" specs/current/spec.md)

# Создание плана
REQUIRED_AGENTS_FILE=".tmp/current/required-agents.json"
mkdir -p .tmp/current/

# Извлечение требований
cat > "$REQUIRED_AGENTS_FILE" << 'EOF'
{
  "orc_": [],
  "work_": [],
  "needs_creation": []
}
EOF
```

**Проблемы:**

1. ❌ **Путь к спецификации:**
   - Использует `specs/current/spec.md`
   - Должно быть: `.qwen/specify/specs/{ID}-{feature}/spec.md`

2. ❌ **Путь к плану:**
   - Использует `.tmp/current/`
   - Должно быть: `.qwen/specify/specs/{ID}-{feature}/plans/`

3. ❌ **Отсутствие интеграции со speckit:**
   - Нет связи с `speckit.plan`
   - Нет связи с `speckit.tasks`

4. ⚠️ **Простая логика:**
   - Только базовый анализ
   - Нет классификации задач
   - Нет определения доменов

---

## 2. ПРОБЛЕМЫ ИНТЕГРАЦИИ

### 2.1. Конфликт путей

**Текущее состояние:**
```
Фаза 0 использует:
- specs/current/spec.md
- .tmp/current/plans/
- .tmp/current/required-agents.json

Команды Speckit используют:
- .specify/specs/{ID}-{feature}/
- .specify/templates/
- .specify/scripts/
```

**Новая структура (`.qwen/specify/`):**
```
.qwen/specify/specs/001-feature/
├── spec.md
├── plan.md
├── tasks.md
└── plans/
    └── phase0-plan.json
```

**Проблема:** Фаза 0 не интегрирована с новой структурой!

---

### 2.2. Отсутствие связи со Speckit

**Текущий процесс:**
```
speckit.specify → speckit.plan → speckit.tasks → speckit.implement
     ↓
  (нет Фазы 0)
```

**Должно быть:**
```
speckit.specify → Фаза 0 → speckit.plan → speckit.tasks → speckit.implement
                          ↓
                    orc_planning_task_analyzer
```

---

### 2.3. Проблемы в командах Speckit

**speckit.plan.md:**
- ❌ Не упоминает Фазу 0
- ❌ Не вызывает `orc_planning_task_analyzer`
- ❌ Не использует `phase0-analyzer.sh`

**speckit.tasks.md:**
- ❌ Не использует результаты Фазы 0
- ❌ Не читает `.qwen/specify/specs/{ID}/plans/phase0-plan.json`

**speckit.implement.md:**
- ❌ Не проверяет завершение Фазы 0
- ❌ Нет Gate 0: Pre-Planning Gate

---

## 3. ПЛАН ИНТЕГРАЦИИ

### Этап 1: Обновление phase0-analyzer.sh

**Новая версия скрипта:**

```bash
#!/bin/bash
# Скрипт: .qwen/specify/scripts/phase0-analyzer.sh
# Назначение: Анализ задач спецификации и создание плана Фазы 0

set -e

SPEC_DIR="$1"

if [ -z "$SPEC_DIR" ]; then
    echo "Использование: $0 <путь-к-спецификации>"
    echo "Пример: $0 .qwen/specify/specs/001-user-auth"
    exit 1
fi

SPEC_FILE="$SPEC_DIR/spec.md"
if [ ! -f "$SPEC_FILE" ]; then
    echo "❌ ОШИБКА: Спецификация не найдена: $SPEC_FILE"
    exit 1
fi

echo "=== Фаза 0: Анализ планирования ==="
echo "Спецификация: $SPEC_FILE"

# Создание директории для планов
PLAN_DIR="$SPEC_DIR/plans"
mkdir -p "$PLAN_DIR"

# Анализ задач из спецификации
echo "🔍 Анализ задач..."
TASKS=$(grep -c "^\- \[ \]" "$SPEC_DIR/tasks.md" 2>/dev/null || echo 0)
echo "✅ Найдено задач: $TASKS"

# Определение требуемых агентов
echo "🤖 Определение требуемых агентов..."
AGENTS_FILE="$PLAN_DIR/phase0-agents.json"

cat > "$AGENTS_FILE" << EOF
{
  "specification": "$SPEC_FILE",
  "analyzedAt": "$(date -Iseconds)",
  "requiredAgents": {
    "orchestrators": [],
    "workers": []
  },
  "missingAgents": [],
  "mcpRecommendations": []
}
EOF

# Создание плана Фазы 0
PLAN_FILE="$PLAN_DIR/phase0-plan.json"
cat > "$PLAN_FILE" << EOF
{
  "phase": 0,
  "specification": "$SPEC_FILE",
  "createdAt": "$(date -Iseconds)",
  "status": "initialized",
  "config": {
    "priority": "high",
    "scope": ["$SPEC_DIR"]
  },
  "validation": {
    "required": ["task-analysis", "agent-determination"],
    "optional": ["mcp-recommendations"]
  },
  "mcpGuidance": {
    "recommended": ["mcp__context7__*"],
    "library": "planning",
    "reason": "Проверка текущих шаблонов планирования"
  },
  "nextAgent": "orc_planning_task_analyzer"
}
EOF

echo "✅ План Фазы 0 создан: $PLAN_FILE"
echo "✅ Анализ агентов создан: $AGENTS_FILE"

# Возврат JSON с результатами
echo ""
echo "📊 Результаты:"
cat "$PLAN_FILE"
```

---

### Этап 2: Обновление orc_planning_task_analyzer.md

**Добавить интеграцию с `.qwen/specify/`:**

```markdown
## Интеграция с .qwen/specify/

### Использование

1. **Вызов из speckit.plan:**
   ```bash
   .qwen/specify/scripts/phase0-analyzer.sh .qwen/specify/specs/001-feature
   ```

2. **Чтение плана Фазы 0:**
   ```bash
   cat .qwen/specify/specs/001-feature/plans/phase0-plan.json
   ```

3. **Анализ задач:**
   - Прочитать `tasks.md`
   - Классифицировать задачи по доменам
   - Определить требуемых агентов

4. **Создание назначений:**
   - Обновить `phase0-agents.json`
   - Создать `phase0-assignments.json`

### Обновленный процесс

1. **Получить план Фазы 0**
   - Прочитать `.qwen/specify/specs/{ID}/plans/phase0-plan.json`
   - Извлечь конфигурацию и рекомендации MCP

2. **Анализ задач**
   - Прочитать `tasks.md`
   - Классифицировать по типам: backend, frontend, testing, documentation
   - Оценить сложность: simple, moderate, complex

3. **Определение агентов**
   - Для backend задач: `orc_backend_api_coordinator`
   - Для frontend задач: `orc_frontend_ui_coordinator`
   - Для testing задач: `orc_testing_quality_assurer`
   - Для documentation задач: `tech-translator-ru`

4. **Назначение исполнителей**
   - Проверить наличие агентов в `.qwen/agents/`
   - Назначить подходящих
   - Создать задачи для отсутствующих

5. **Создание отчета**
   - Использовать `generate-report-header`
   - Сохранить в `phase0-report.md`
```

---

### Этап 3: Обновление команд Speckit

**3.1. speckit.plan.md**

**Добавить шаг Фазы 0:**

```markdown
## Процесс выполнения

### 0. Инициализация Фазы 0

Перед началом планирования:

```bash
# Запустить анализ Фазы 0
.qwen/specify/scripts/phase0-analyzer.sh .qwen/specify/specs/{ID}-{feature}

# Проверить результаты
cat .qwen/specify/specs/{ID}/plans/phase0-plan.json
```

### 1. Чтение результатов Фазы 0

Загрузить и проанализировать:
- `phase0-plan.json` — план Фазы 0
- `phase0-agents.json` — требуемые агенты
- `phase0-assignments.json` — назначенные исполнители

### 2. Создание плана реализации

Использовать информацию из Фазы 0 для:
- Определения последовательности задач
- Выбора технологического стека
- Назначения агентов на задачи
```

**3.2. speckit.tasks.md**

**Добавить интеграцию:**

```markdown
## Процесс выполнения

### 0. Проверка Фазы 0

Перед генерацией задач:

```bash
# Проверить завершение Фазы 0
if [ ! -f ".qwen/specify/specs/{ID}/plans/phase0-plan.json" ]; then
    echo "❌ ОШИБКА: Фаза 0 не завершена"
    echo "Запустите /speckit.plan для инициализации"
    exit 1
fi
```

### 1. Чтение назначений Фазы 0

Загрузить `phase0-assignments.json` для:
- Списка задач с классификацией
- Назначенных агентов
- Рекомендаций MCP
```

**3.3. speckit.implement.md**

**Добавить проверку:**

```markdown
## Проверка перед реализацией

### Gate 0: Pre-Planning Gate

Перед началом реализации:

```bash
# Проверить завершение Фазы 0
if [ ! -f ".qwen/specify/specs/{ID}/plans/phase0-plan.json" ]; then
    echo "❌ Фаза 0 не завершена"
    exit 1
fi

# Проверить Quality Gate 1
.qwen/scripts/quality-gates/check-planning.sh
```

Только после успешной проверки переходить к реализации.
```

---

### Этап 4: Создание Quality Gate для Фазы 0

**Файл:** `.qwen/scripts/quality-gates/check-planning.sh`

```bash
#!/bin/bash
# Скрипт: check-planning.sh
# Назначение: Проверка качества планирования (Gate 1)

SPEC_DIR="$1"

if [ -z "$SPEC_DIR" ]; then
    echo "Использование: $0 <путь-к-спецификации>"
    exit 1
fi

ERRORS=0

# Проверка наличия плана Фазы 0
if [ ! -f "$SPEC_DIR/plans/phase0-plan.json" ]; then
    echo "❌ План Фазы 0 отсутствует"
    ERRORS=$((ERRORS + 1))
else
    echo "✅ План Фазы 0 найден"
fi

# Проверка наличия assignments
if [ ! -f "$SPEC_DIR/plans/phase0-assignments.json" ]; then
    echo "❌ Назначения агентов отсутствуют"
    ERRORS=$((ERRORS + 1))
else
    echo "✅ Назначения агентов найдены"
fi

# Проверка наличия tasks.md
if [ ! -f "$SPEC_DIR/tasks.md" ]; then
    echo "❌ tasks.md отсутствует"
    ERRORS=$((ERRORS + 1))
else
    echo "✅ tasks.md найден"
fi

# Проверка наличия plan.md
if [ ! -f "$SPEC_DIR/plan.md" ]; then
    echo "❌ plan.md отсутствует"
    ERRORS=$((ERRORS + 1))
else
    echo "✅ plan.md найден"
fi

# Вывод результатов
if [ $ERRORS -gt 0 ]; then
    echo ""
    echo "❌ Planning Gate не пройден ($ERRORS ошибок)"
    exit 1
fi

echo ""
echo "✅ Planning Gate пройден"
exit 0
```

---

### Этап 5: Обновление документации

**5.1. planning-phase.md**

**Добавить раздел:**

```markdown
## Интеграция с .qwen/specify/

### Структура файлов

```
.qwen/specify/specs/001-feature/
├── spec.md
├── plan.md
├── tasks.md
└── plans/
    ├── phase0-plan.json       # План Фазы 0
    ├── phase0-agents.json     # Требуемые агенты
    └── phase0-assignments.json # Назначения
```

### Процесс интеграции

1. **speckit.specify** создает спецификацию
2. **speckit.plan** инициирует Фазу 0
3. **orc_planning_task_analyzer** выполняет анализ
4. **Результаты** сохраняются в `plans/phase0-*.json`
5. **speckit.tasks** использует результаты Фазы 0
6. **speckit.implement** проверяет завершение Фазы 0
```

**5.2. specification-driven-development.md**

**Добавить раздел:**

```markdown
## Фаза 0 в процессе Speckit

### Место в процессе

```
speckit.specify
    ↓
speckit.plan → Фаза 0 (orc_planning_task_analyzer)
    ↓
speckit.tasks → Использует результаты Фазы 0
    ↓
speckit.implement → Проверяет Gate 1
```

### Контрольные точки

- **Gate 0:** Pre-Planning (перед Фазой 0)
- **Gate 1:** Planning Quality (после Фазы 0)
- **Gate 2:** Task Quality (после tasks.md)
```

---

## 4. МАТРИЦА ИНТЕГРАЦИИ

### 4.1. Компоненты и зависимости

| Компонент | Использует | Создает | Интегрируется с |
|-----------|------------|---------|-----------------|
| phase0-analyzer.sh | spec.md, tasks.md | phase0-plan.json | speckit.plan |
| orc_planning_task_analyzer | phase0-plan.json | phase0-report.md | work_* агенты |
| speckit.plan | spec.md | plan.md | Фаза 0 |
| speckit.tasks | phase0-assignments.json | tasks.md | Фаза 0 |
| speckit.implement | tasks.md, plan.md | код | Gate 1 |
| check-planning.sh | phase0-*.json | отчет | Quality Gates |

### 4.2. Приоритеты интеграции

**Priority 0 (Критическое):**
1. Обновить `phase0-analyzer.sh` для `.qwen/specify/`
2. Обновить `orc_planning_task_analyzer.md`
3. Добавить интеграцию в `speckit.plan.md`

**Priority 1 (Высокое):**
4. Добавить интеграцию в `speckit.tasks.md`
5. Добавить интеграцию в `speckit.implement.md`
6. Создать `check-planning.sh`

**Priority 2 (Среднее):**
7. Обновить документацию
8. Добавить примеры

---

## 5. ВРЕМЕННАЯ ШКАЛА

**Неделя 1:**
- День 1-2: Обновление `phase0-analyzer.sh`
- День 3: Обновление `orc_planning_task_analyzer.md`

**Неделя 2:**
- День 1-2: Интеграция в Speckit команды
- День 3: Создание Quality Gate

**Неделя 3:**
- Обновление документации
- Тестирование интеграции

---

## 6. ВЫВОДЫ

### 6.1. Текущее состояние

**Фаза 0 реализована частично:**
- ✅ Скрипт `phase0-analyzer.sh` существует
- ✅ Оркестратор `orc_planning_task_analyzer` существует
- ✅ Воркеры существуют
- ✅ Схема существует

**Проблемы:**
- ❌ Не интегрирована с `.qwen/specify/`
- ❌ Не интегрирована со Speckit командами
- ❌ Использует устаревшие пути
- ❌ Нет Quality Gate для планирования

### 6.2. Рекомендации

**Критические:**
1. Обновить `phase0-analyzer.sh` для `.qwen/specify/`
2. Интегрировать в `speckit.plan`
3. Добавить проверки в `speckit.implement`

**Важные:**
4. Создать Quality Gate для планирования
5. Обновить документацию
6. Добавить тесты

---

**Отчет готов к реализации!**
