# Стандарт взаимодействия оркестраторов

**Версия:** 1.0.0  
**Дата:** 21 марта 2026  
**Статус:** Активный  
**Проект:** Qwen Code Orchestrator Kit v0.6.0

---

## 1. Обзор

Этот стандарт определяет паттерны взаимодействия между оркестраторами в системе Qwen Code Orchestrator Kit. Стандарт обеспечивает согласованность, предсказуемость и надежность межкомпонентной коммуникации.

### 1.1. Цели стандарта

- Унификация паттернов взаимодействия
- Минимизация耦合 (coupling) между компонентами
- Обеспечение отказоустойчивости
- Упрощение отладки и мониторинга

### 1.2. Область применения

Стандарт применяется ко всем оркестраторам в системе:
- `orc_planning_task_analyzer`
- `orc_dev_task_coordinator`
- `orc_backend_api_coordinator`
- `orc_frontend_ui_coordinator`
- `orc_testing_quality_assurer`
- `orc_security_security_orchestrator`
- `orc_research_data_analyzer`

---

## 2. Паттерны взаимодействия

### 2.1. Последовательная оркестрация (Chain Pattern)

**Схема:** A → B → C

```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│ Orchestrator│───▶│ Orchestrator│───▶│ Orchestrator│
│     A       │    │     B       │    │     C       │
└─────────────┘    └─────────────┘    └─────────────┘
      │                  │                  │
      ▼                  ▼                  ▼
  Planning          Development         Testing
```

**Использование:**
- Многофазные рабочие процессы
- Задачи с явными зависимостями
- Линейные пайплайны обработки

**Пример:**
```bash
# Фаза 1: Планирование
orc_planning_task_analyzer --spec SPEC-001 --output-plan

# Фаза 2: Разработка (ждет завершения фазы 1)
orc_dev_task_coordinator --spec SPEC-001 --plan phase0-plan.json

# Фаза 3: Тестирование (ждет завершения фазы 2)
orc_testing_quality_assurer --spec SPEC-001 --phase test
```

**Требования:**
- Каждый оркестратор должен генерировать артефакты для следующего
- Явная передача контекста через файлы
- Валидация входных данных каждого этапа

**Формат передачи контекста:**
```json
{
  "sourceOrchestrator": "orc_planning_task_analyzer",
  "targetOrchestrator": "orc_dev_task_coordinator",
  "artifacts": [
    "specs/SPEC-001/plans/phase0-plan.json",
    "specs/SPEC-001/plans/phase0-assignments.json"
  ],
  "context": {
    "specId": "SPEC-001",
    "phase": "development",
    "priority": "high"
  }
}
```

---

### 2.2. Параллельная оркестрация (Fan-Out Pattern)

**Схема:** A → [B, C, D]

```
                    ┌─────────────┐
                    │ Orchestrator│
                    │     A       │
                    └──────┬──────┘
                           │
         ┌─────────────────┼─────────────────┐
         │                 │                 │
         ▼                 ▼                 ▼
  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐
  │ Orchestrator│  │ Orchestrator│  │ Orchestrator│
  │     B       │  │     C       │  │     D       │
  └─────────────┘  └─────────────┘  └─────────────┘
   Backend          Frontend         Testing
```

**Использование:**
- Независимые подзадачи
- Параллельная обработка компонентов
- Распределение нагрузки

**Пример:**
```bash
# Главный оркестратор запускает параллельные задачи
orc_dev_task_coordinator --spec SPEC-001 --parallel

# Параллельное выполнение:
# 1. Backend разработка
orc_backend_api_coordinator --spec SPEC-001 --component api &

# 2. Frontend разработка  
orc_frontend_ui_coordinator --spec SPEC-001 --component ui &

# 3. Параллельное тестирование
orc_testing_quality_assurer --spec SPEC-001 --component tests &

# Ожидание завершения всех
wait
```

**Требования:**
- Изоляция контекста между параллельными ветками
- Механизм синхронизации завершения
- Агрегация результатов

**Формат агрегации:**
```json
{
  "aggregator": "orc_dev_task_coordinator",
  "parallelBranches": [
    {
      "orchestrator": "orc_backend_api_coordinator",
      "status": "success",
      "artifacts": ["specs/SPEC-001/reports/backend-report.md"]
    },
    {
      "orchestrator": "orc_frontend_ui_coordinator", 
      "status": "success",
      "artifacts": ["specs/SPEC-001/reports/frontend-report.md"]
    }
  ],
  "overallStatus": "success"
}
```

---

### 2.3. Условная оркестрация (Conditional Pattern)

**Схема:** A → if X then B else C

```
                    ┌─────────────┐
                    │ Orchestrator│
                    │     A       │
                    └──────┬──────┘
                           │
                           ▼
                    ┌─────────────┐
                    │  Condition  │
                    │     X?      │
                    └──────┬──────┘
                           │
              ┌────────────┴────────────┐
              │                         │
             YES                       NO
              │                         │
              ▼                         ▼
       ┌─────────────┐          ┌─────────────┐
       │ Orchestrator│          │ Orchestrator│
       │     B       │          │     C       │
       └─────────────┘          └─────────────┘
        Primary Path            Fallback Path
```

**Использование:**
- Обработка ошибок
- Fallback сценарии
- Адаптивные рабочие процессы

**Пример:**
```bash
# Основной оркестратор проверяет условие
result=$(orc_planning_task_analyzer --spec SPEC-001 --validate)

if [ "$result" == "complex" ]; then
    # Сложная задача - полный пайплайн
    orc_dev_task_coordinator --spec SPEC-001 --mode full
else
    # Простая задача - упрощенный пайплайн
    orc_dev_task_coordinator --spec SPEC-001 --mode simple
fi
```

**Типы условий:**
| Условие | Описание | Пример |
|---------|----------|--------|
| `complexity` | Сложность задачи | high/medium/low |
| `priority` | Приоритет задачи | critical/high/medium/low |
| `type` | Тип задачи | feature/bugfix/refactor |
| `scope` | Область изменений | large/medium/small |
| `risk` | Уровень риска | high/medium/low |

**Формат условия:**
```json
{
  "condition": {
    "type": "complexity",
    "operator": ">=",
    "value": "medium"
  },
  "trueBranch": {
    "orchestrator": "orc_dev_task_coordinator",
    "mode": "full",
    "timeout": 600000
  },
  "falseBranch": {
    "orchestrator": "orc_dev_task_coordinator",
    "mode": "simple",
    "timeout": 300000
  }
}
```

---

### 2.4. Циклическая оркестрация (Retry Pattern)

**Схема:** A → retry B until success

```
┌─────────────┐     ┌─────────────┐
│ Orchestrator│────▶│ Orchestrator│
│     A       │     │     B       │
└─────────────┘     └──────┬──────┘
                           │
                           ▼
                    ┌─────────────┐
                    │   Success?  │
                    └──────┬──────┘
                           │
              ┌────────────┴────────────┐
              │                         │
             NO                       YES
              │                         │
              ▼                         ▼
       ┌─────────────┐          ┌─────────────┐
       │   Retry     │          │  Continue   │
       │  (max N)    │          │             │
       └──────┬──────┘          └─────────────┘
              │
              └──────────────────┘
```

**Использование:**
- Нестабильные операции
- Внешние зависимости
- Восстановление после ошибок

**Пример:**
```bash
# Оркестратор с retry логикой
max_retries=3
retry_count=0

while [ $retry_count -lt $max_retries ]; do
    result=$(orc_testing_quality_assurer --spec SPEC-001 --phase test)
    
    if [ "$result" == "success" ]; then
        echo "Tests passed"
        break
    fi
    
    retry_count=$((retry_count + 1))
    echo "Retry $retry_count/$max_retries"
    sleep 5
done

if [ $retry_count -eq $max_retries ]; then
    echo "Max retries reached, escalating"
    orc_planning_task_analyzer --spec SPEC-001 --escalate
fi
```

**Конфигурация retry:**
```json
{
  "retry": {
    "enabled": true,
    "maxAttempts": 3,
    "delayMs": 5000,
    "backoff": "exponential",
    "maxDelayMs": 60000,
    "retryableErrors": [
      "TIMEOUT",
      "NETWORK_ERROR",
      "RESOURCE_BUSY"
    ],
    "nonRetryableErrors": [
      "VALIDATION_ERROR",
      "CONFIGURATION_ERROR",
      "PERMISSION_DENIED"
    ]
  }
}
```

---

## 3. Механизмы передачи данных

### 3.1. Файловая передача (File-Based)

**Рекомендуемый способ для большинства сценариев**

```
┌─────────────┐                    ┌─────────────┐
│ Orchestrator│                    │ Orchestrator│
│  Producer   │                    │  Consumer   │
└──────┬──────┘                    └──────▲──────┘
       │                                  │
       │  1. Запись артефактов            │
       │─────────────────────────────────▶│
       │     specs/{ID}/artifacts/        │
       │                                  │
       │  2. Чтение артефактов            │
       │◀─────────────────────────────────│
       │                                  │
```

**Структура артефактов:**
```
specs/
└── SPEC-001/
    ├── artifacts/
    │   ├── phase0-plan.json
    │   ├── phase0-assignments.json
    │   └── context.json
    ├── reports/
    │   ├── planning-report.md
    │   └── development-report.md
    └── summary.md
```

### 3.2. Контекстная передача (Context-Based)

**Для легкой передачи метаданных**

```json
{
  "context": {
    "specId": "SPEC-001",
    "currentPhase": "development",
    "previousPhase": "planning",
    "orchestratorChain": [
      "orc_planning_task_analyzer",
      "orc_dev_task_coordinator"
    ],
    "artifacts": {
      "plan": "specs/SPEC-001/plans/phase0-plan.json",
      "assignments": "specs/SPEC-001/plans/phase0-assignments.json"
    },
    "state": {
      "completedTasks": 5,
      "totalTasks": 10,
      "errors": []
    }
  }
}
```

### 3.3. Событийная передача (Event-Based)

**Для асинхронной коммуникации**

```bash
# Публикация события
.qwen/scripts/events/publish.sh "phase.completed" \
  --spec SPEC-001 \
  --phase planning \
  --orchestrator orc_planning_task_analyzer

# Подписка на событие
.qwen/scripts/events/subscribe.sh "phase.completed" \
  --handler .qwen/scripts/handlers/phase-completed.sh
```

---

## 4. Обработка ошибок

### 4.1. Эскалация ошибок

```
┌─────────────┐
│ Orchestrator│
│     B       │
└──────┬──────┘
       │ Error
       ▼
┌─────────────┐     ┌─────────────┐
│   Handler   │────▶│ Orchestrator│
│   (local)   │     │     A       │
└─────────────┘     │ (upstream)  │
                    └─────────────┘
```

**Уровни эскалации:**
1. **Local Handler** - Обработка внутри оркестратора
2. **Upstream Orchestrator** - Эскалация вызывающему оркестратору
3. **System Handler** - Глобальная обработка ошибок
4. **Manual Intervention** - Требует вмешательства человека

**Формат сообщения об ошибке:**
```json
{
  "error": {
    "code": "ORC_PHASE_FAILED",
    "severity": "high",
    "source": "orc_dev_task_coordinator",
    "phase": "development",
    "specId": "SPEC-001",
    "message": "Quality gate failed: type-check",
    "details": {
      "failedCheck": "type-check",
      "errorCount": 3,
      "affectedFiles": ["src/module.ts", "lib/utils.ts"]
    },
    "timestamp": "2026-03-21T10:30:00Z",
    "recovery": {
      "suggested": ["fix-type-errors", "skip-optional-checks"],
      "autoRetry": false
    }
  }
}
```

### 4.2. Graceful Degradation

При ошибке одного оркестратора система должна деградировать gracefully:

```bash
# Попытка основного пути
if ! orc_dev_task_coordinator --spec SPEC-001 --mode full; then
    echo "Full mode failed, attempting simplified mode"
    
    # Упрощенный режим
    if ! orc_dev_task_coordinator --spec SPEC-001 --mode simple; then
        echo "Simple mode failed, escalating"
        
        # Эскалация
        orc_planning_task_analyzer --spec SPEC-001 --escalate
    fi
fi
```

---

## 5. Мониторинг и логирование

### 5.1. Формат логов

```
[TIMESTAMP] [LEVEL] [ORCHESTRATOR] [PHASE] MESSAGE

# Примеры
[2026-03-21T10:30:00.000Z] [INFO] [orc_dev_task_coordinator] [INIT] Starting orchestration
[2026-03-21T10:30:01.000Z] [INFO] [orc_dev_task_coordinator] [PLAN] Loading plan from specs/SPEC-001/plans/phase0-plan.json
[2026-03-21T10:30:02.000Z] [INFO] [orc_dev_task_coordinator] [DELEGATE] Calling work_dev_code_analyzer
[2026-03-21T10:35:00.000Z] [INFO] [orc_dev_task_coordinator] [VERIFY] Verification completed
[2026-03-21T10:35:01.000Z] [INFO] [orc_dev_task_coordinator] [QGate] Running quality gate: type-check
[2026-03-21T10:35:05.000Z] [ERROR] [orc_dev_task_coordinator] [QGate] Quality gate failed: type-check
[2026-03-21T10:35:06.000Z] [INFO] [orc_dev_task_coordinator] [SHUTDOWN] Graceful shutdown initiated
```

### 5.2. Метрики взаимодействия

| Метрика | Описание | Формат |
|---------|----------|--------|
| `orchestration.duration` | Длительность оркестрации | ms |
| `orchestration.delegations` | Количество делегирований | count |
| `orchestration.retries` | Количество повторных попыток | count |
| `orchestration.errors` | Количество ошибок | count |
| `orchestration.success_rate` | Процент успешных выполнений | % |

### 5.3. Трассировка

```json
{
  "traceId": "trace-20260321-103000-001",
  "spanId": "span-orch-dev-001",
  "parentSpanId": "span-orch-plan-001",
  "orchestrator": "orc_dev_task_coordinator",
  "startTime": "2026-03-21T10:30:00.000Z",
  "endTime": "2026-03-21T10:40:00.000Z",
  "duration": 600000,
  "status": "success",
  "tags": {
    "specId": "SPEC-001",
    "phase": "development",
    "priority": "high"
  }
}
```

---

## 6. Best Practices

### 6.1. Дизайн взаимодействия

✅ **Делайте:**
- Явно определяйте контракты между оркестраторами
- Используйте файловую передачу для артефактов
- Логируйте все вызовы и ответы
- Реализуйте graceful degradation
- Тестируйте сценарии ошибок

❌ **Не делайте:**
- Прямые вызовы между оркестраторами без контекста
- Передачу больших данных через аргументы командной строки
- Игнорирование ошибок от зависимых оркестраторов
- Создание циклических зависимостей

### 6.2. Управление состоянием

```bash
# Сохранение состояния перед делегированием
.qwen/scripts/state/save.sh "orchestrator" "orc_dev_task_coordinator"

# Восстановление состояния после ошибки
.qwen/scripts/state/restore.sh "orchestrator" "orc_dev_task_coordinator"
```

### 6.3. Валидация контекста

```bash
# Валидация входящего контекста
.qwen/scripts/validation/validate-context.sh \
  --expected-schema .qwen/schemas/orchestrator-context.json \
  --context-file specs/SPEC-001/context.json
```

---

## 7. Примеры реализации

### 7.1. Полный пайплайн разработки

```bash
#!/bin/bash
# .qwen/scripts/pipelines/full-dev-pipeline.sh

SPEC_ID=$1

echo "=== Starting Full Development Pipeline ==="
echo "Spec ID: $SPEC_ID"

# Фаза 1: Планирование
echo "[Phase 1/4] Planning..."
orc_planning_task_analyzer --spec $SPEC_ID
if [ $? -ne 0 ]; then
    echo "Planning failed, aborting"
    exit 1
fi

# Фаза 2: Разработка (параллельно)
echo "[Phase 2/4] Development (parallel)..."
orc_backend_api_coordinator --spec $SPEC_ID &
BACKEND_PID=$!

orc_frontend_ui_coordinator --spec $SPEC_ID &
FRONTEND_PID=$!

wait $BACKEND_PID
BACKEND_STATUS=$?

wait $FRONTEND_PID
FRONTEND_STATUS=$?

if [ $BACKEND_STATUS -ne 0 ] || [ $FRONTEND_STATUS -ne 0 ]; then
    echo "Development failed, attempting recovery..."
    orc_dev_task_coordinator --spec $SPEC_ID --recover
fi

# Фаза 3: Тестирование
echo "[Phase 3/4] Testing..."
orc_testing_quality_assurer --spec $SPEC_ID
if [ $? -ne 0 ]; then
    echo "Testing failed, retrying..."
    orc_testing_quality_assurer --spec $SPEC_ID --retry
fi

# Фаза 4: Безопасность
echo "[Phase 4/4] Security..."
orc_security_security_orchestrator --spec $SPEC_ID

echo "=== Pipeline Completed ==="
```

### 7.2. Обработка ошибок с retry

```bash
#!/bin/bash
# .qwen/scripts/pipelines/retry-pattern.sh

SPEC_ID=$1
MAX_RETRIES=3
RETRY_COUNT=0
DELAY=5

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    echo "Attempt $((RETRY_COUNT + 1))/$MAX_RETRIES"
    
    orc_testing_quality_assurer --spec $SPEC_ID --phase test
    RESULT=$?
    
    if [ $RESULT -eq 0 ]; then
        echo "Success!"
        exit 0
    fi
    
    echo "Failed, retrying in ${DELAY}s..."
    sleep $DELAY
    
    RETRY_COUNT=$((RETRY_COUNT + 1))
    DELAY=$((DELAY * 2))  # Exponential backoff
done

echo "Max retries reached, escalating"
orc_planning_task_analyzer --spec $SPEC_ID --escalate
exit 1
```

---

## 8. Чеклист реализации

### 8.1. При создании нового оркестратора

- [ ] Определены входные артефакты
- [ ] Определены выходные артефакты
- [ ] Настроена передача контекста
- [ ] Реализована обработка ошибок
- [ ] Настроено логирование
- [ ] Определены зависимости от других оркестраторов

### 8.2. При интеграции оркестраторов

- [ ] Контракты между оркестраторами документированы
- [ ] Форматы артефактов согласованы
- [ ] Обработаны сценарии ошибок
- [ ] Настроена трассировка
- [ ] Протестированы все паттерны взаимодействия

---

**Документ утвержден:** Qwen Code Orchestrator Kit Team  
**Дата утверждения:** 21 марта 2026  
**Следующий пересмотр:** 21 июня 2026
