---
name: progress-logging
description: Логирование прогресса выполнения. Форматирование сообщений, отслеживание % выполнения, вывод времени до завершения, логирование каждого шага.
---

# Progress Logging Skill

## Когда использовать
- При выполнении длительных задач (> 1 минуты)
- Для отслеживания прогресса многошаговых процессов
- При необходимости оценки времени до завершения
- Для отладки и мониторинга выполнения задач

## Инструкции

### 1. Форматирование Сообщений Прогресса

**Стандартный формат сообщения:**

```
[PROGRESS] {timestamp} | {task-id} | {phase} | {step}/{total} ({percent}%) | {message}
```

**Примеры:**

```
[PROGRESS] 2026-03-21T14:30:25+03:00 | dev-task-123 | phase-2 | 3/10 (30%) | Анализ кода завершен
[PROGRESS] 2026-03-21T14:31:00+03:00 | dev-task-123 | phase-2 | 4/10 (40%) | Генерация тестов...
[PROGRESS] 2026-03-21T14:32:15+03:00 | dev-task-123 | phase-2 | 5/10 (50%) | halfway point reached
```

**Уровни детализации:**

```bash
# INFO - Общая информация
[PROGRESS][INFO] {message}

# DEBUG - Детальная отладка
[PROGRESS][DEBUG] {detailed-message}

# WARN - Предупреждения
[PROGRESS][WARN] {warning-message}

# ERROR - Ошибки
[PROGRESS][ERROR] {error-message}
```

### 2. Отслеживание % Выполнения

**Формула расчета:**

```
percent = (completed_steps / total_steps) * 100
```

**Прогресс-бар в логе:**

```bash
# Текстовый прогресс-бар
██████████░░░░░░░░░░ 50% | 5/10 шагов

# Символы для прогресс-бара
FULL_BLOCK="█"
EMPTY_BLOCK="░"
BAR_WIDTH=20

filled=$((percent * BAR_WIDTH / 100))
empty=$((BAR_WIDTH - filled))

printf "["
printf "%${filled}s" | tr ' ' '█'
printf "%${empty}s" | tr ' ' '░'
printf "] %3d%% | %d/%d шагов\n" "$percent" "$completed" "$total"
```

**Таблица прогресса:**

| Шаг | Статус | Описание | Время |
|-----|--------|----------|-------|
| 1 | ✅ | Инициализация | 0.5s |
| 2 | ✅ | Чтение плана | 1.2s |
| 3 | 🔄 | Анализ кода | 2.1s |
| 4 | ⏳ | Ожидание | - |
| 5 | ⏸️ | Остановлено | - |

### 3. Вывод Времени до Завершения

**Расчет ETA (Estimated Time of Arrival):**

```bash
#!/bin/bash
# Расчет времени до завершения

start_time=$(date +%s)
completed=$1
total=$2

elapsed=$(($(date +%s) - start_time))
avg_time_per_step=$((elapsed / completed))
remaining_steps=$((total - completed))
eta_seconds=$((avg_time_per_step * remaining_steps))

# Форматирование ETA
if [ $eta_seconds -lt 60 ]; then
    eta_formatted="${eta_seconds}с"
elif [ $eta_seconds -lt 3600 ]; then
    eta_formatted="$((eta_seconds / 60))м $((eta_seconds % 60))с"
else
    eta_formatted="$((eta_seconds / 3600))ч $((eta_seconds % 3600 / 60))м"
fi

echo "Осталось времени: ${eta_formatted}"
```

**Формат вывода ETA:**

```
⏱️  Прошло: 2м 30с | Среднее на шаг: 30с | ETA: 2м 30с | Завершение: ~14:35
```

**Прогресс с временными метками:**

```json
{
  "taskId": "dev-task-123",
  "startTime": "2026-03-21T14:30:00+03:00",
  "currentTime": "2026-03-21T14:32:30+03:00",
  "elapsed": "2м 30с",
  "completed": 5,
  "total": 10,
  "percent": 50,
  "avgTimePerStep": "30с",
  "eta": "2м 30с",
  "estimatedCompletion": "2026-03-21T14:35:00+03:00"
}
```

### 4. Логирование Каждого Шага

**Структура лога шага:**

```markdown
## Шаг {N}: {название шага}

**Статус**: {pending|in_progress|completed|failed|skipped}
**Начало**: {timestamp}
**Конец**: {timestamp}
**Длительность**: {duration}

### Действия
- Действие 1: результат
- Действие 2: результат

### Изменения
- Созданные файлы: {список}
- Измененные файлы: {список}
- Удаленные файлы: {список}

### Вывод команд
\`\`\`bash
{вывод команд}
\`\`\`

### Ошибки
{описание ошибок, если есть}
```

**Автоматическое логирование через wrapper:**

```bash
#!/bin/bash
# .qwen/scripts/logging/log-step.sh

STEP_NUM=$1
STEP_NAME=$2
TASK_ID=$3
LOG_FILE=".qwen/logs/${TASK_ID}-steps.log"

echo "" >> "$LOG_FILE"
echo "========================================" >> "$LOG_FILE"
echo "ШАГ ${STEP_NUM}: ${STEP_NAME}" >> "$LOG_FILE"
echo "Начало: $(date -Iseconds)" >> "$LOG_FILE"
echo "Статус: in_progress" >> "$LOG_FILE"
echo "========================================" >> "$LOG_FILE"

# Выполнение шага с перехватом вывода
"$@" 2>&1 | tee -a "$LOG_FILE"

EXIT_CODE=$?
echo "" >> "$LOG_FILE"
echo "Конец: $(date -Iseconds)" >> "$LOG_FILE"
echo "Статус: $([ $EXIT_CODE -eq 0 ] && echo 'completed' || echo 'failed')" >> "$LOG_FILE"
echo "Код выхода: ${EXIT_CODE}" >> "$LOG_FILE"

return $EXIT_CODE
```

## Формат ввода

```json
{
  "taskId": "string",
  "taskName": "string",
  "totalSteps": "number",
  "steps": [
    {
      "id": "number",
      "name": "string",
      "estimatedDuration": "number (seconds)"
    }
  ],
  "logLevel": "INFO|DEBUG|WARN|ERROR",
  "outputFormat": "console|file|json|markdown"
}
```

## Формат вывода

### Console Output

```
╔════════════════════════════════════════════════════════╗
║  Task: dev-task-123                                    ║
║  Progress: ████████████░░░░░░░░░░ 60% | 6/10 шагов    ║
║  Elapsed: 3м 0с | ETA: 2м 0с                          ║
╚════════════════════════════════════════════════════════╝

[✓] Шаг 1: Инициализация (0.5с)
[✓] Шаг 2: Чтение плана (1.2с)
[→] Шаг 3: Анализ кода (в процессе...)
[ ] Шаг 4: Генерация тестов
[ ] Шаг 5: Валидация
```

### File Output (JSON)

```json
{
  "taskId": "dev-task-123",
  "logEntries": [
    {
      "timestamp": "2026-03-21T14:30:00+03:00",
      "step": 1,
      "status": "completed",
      "message": "Инициализация завершена",
      "duration": 0.5
    },
    {
      "timestamp": "2026-03-21T14:30:01+03:00",
      "step": 2,
      "status": "completed",
      "message": "План прочитан",
      "duration": 1.2
    }
  ],
  "summary": {
    "totalSteps": 10,
    "completedSteps": 2,
    "percent": 20,
    "elapsedTime": "1.7с",
    "estimatedRemaining": "8.5с"
  }
}
```

### Markdown Output

```markdown
# Progress Report: dev-task-123

## Summary
- **Status**: In Progress
- **Progress**: 60% (6/10 steps)
- **Elapsed**: 3м 0с
- **ETA**: 2м 0с

## Step History

| # | Step | Status | Duration |
|---|------|--------|----------|
| 1 | Инициализация | ✅ Completed | 0.5с |
| 2 | Чтение плана | ✅ Completed | 1.2с |
| 3 | Анализ кода | ✅ Completed | 2.1с |
| 4 | Генерация тестов | 🔄 In Progress | - |
| 5 | Валидация | ⏳ Pending | - |

## Current Activity
**Step 4**: Генерация тестов
- Started: 2026-03-21T14:32:00+03:00
- Status: Running...
```

## Примеры

### Пример 1: Логирование задачи разработки

**Вход:**
```json
{
  "taskId": "dev-task-123",
  "taskName": "Реализация функции авторизации",
  "totalSteps": 5,
  "steps": [
    {"id": 1, "name": "Анализ требований", "estimatedDuration": 60},
    {"id": 2, "name": "Проектирование", "estimatedDuration": 120},
    {"id": 3, "name": "Реализация", "estimatedDuration": 300},
    {"id": 4, "name": "Тестирование", "estimatedDuration": 180},
    {"id": 5, "name": "Документирование", "estimatedDuration": 60}
  ]
}
```

**Выход (console):**
```
╔════════════════════════════════════════════════════════╗
║  Task: dev-task-123                                    ║
║  Реализация функции авторизации                        ║
║  Progress: ████████████████░░░░░░ 80% | 4/5 шагов     ║
║  Elapsed: 10м 30с | ETA: 1м 15с                       ║
╚════════════════════════════════════════════════════════╝

[✓] Шаг 1: Анализ требований (58с)
[✓] Шаг 2: Проектирование (2м 5с)
[✓] Шаг 3: Реализация (5м 12с)
[✓] Шаг 4: Тестирование (2м 55с)
[→] Шаг 5: Документирование (в процессе...)
```

### Пример 2: Логирование сборки проекта

```bash
#!/bin/bash
# Логирование процесса сборки

source .qwen/scripts/logging/progress-logger.sh

init_progress "build-task" "Сборка проекта" 6

log_step 1 "Очистка" "rm -rf dist/"
log_step 2 "Установка зависимостей" "npm install"
log_step 3 "Компиляция TypeScript" "tsc"
log_step 4 "Сборка.bundle" "webpack"
log_step 5 "Запуск тестов" "npm test"
log_step 6 "Генерация документации" "npm run docs"

finalize_progress
```

## Интеграция с другими навыками

- `graceful-shutdown` - для сохранения прогресса при timeout
- `generate-report-header` - для генерации отчетов о прогрессе
- `save-session-context` - для сохранения контекста с прогрессом

## Скрипты

### .qwen/scripts/logging/progress-logger.sh
```bash
#!/bin/bash
# Библиотека функций для логирования прогресса

# Инициализация прогресса
init_progress() {
    TASK_ID=$1
    TASK_NAME=$2
    TOTAL_STEPS=$3
    LOG_FILE=".qwen/logs/${TASK_ID}-progress.log"
    
    echo "TASK_ID=${TASK_ID}" > "$LOG_FILE"
    echo "TASK_NAME=${TASK_NAME}" >> "$LOG_FILE"
    echo "TOTAL_STEPS=${TOTAL_STEPS}" >> "$LOG_FILE"
    echo "START_TIME=$(date +%s)" >> "$LOG_FILE"
    echo "COMPLETED_STEPS=0" >> "$LOG_FILE"
}

# Логирование шага
log_step() {
    STEP_NUM=$1
    STEP_NAME=$2
    shift 2
    COMMAND="$@"
    
    echo "[STEP ${STEP_NUM}] ${STEP_NAME} - started at $(date -Iseconds)" >> "$LOG_FILE"
    
    if [ -n "$COMMAND" ]; then
        eval "$COMMAND" 2>&1 | tee -a "$LOG_FILE"
    fi
    
    echo "[STEP ${STEP_NUM}] ${STEP_NAME} - completed at $(date -Iseconds)" >> "$LOG_FILE"
}

# Обновление прогресса
update_progress() {
    COMPLETED=$1
    source "$LOG_FILE"
    
    PERCENT=$((COMPLETED * 100 / TOTAL_STEPS))
    ELAPSED=$(($(date +%s) - START_TIME))
    AVG_TIME=$((ELAPSED / COMPLETED))
    REMAINING=$((TOTAL_STEPS - COMPLETED))
    ETA=$((AVG_TIME * REMAINING))
    
    echo "COMPLETED_STEPS=${COMPLETED}" >> "$LOG_FILE"
    
    # Вывод прогресс-бара
    printf "\r[%-20s] %3d%% | Шаг %d/%d | ETA: %ds" \
        "$(printf '%*s' $((PERCENT / 5)) | tr ' ' '█')" \
        "$PERCENT" "$COMPLETED" "$TOTAL_STEPS" "$ETA"
}
```

## Best Practices

1. **Логируйте каждый шаг** - даже если шаг быстрый
2. **Используйте единый формат** - для парсинга и анализа
3. **Сохраняйте временные метки** - для расчета ETA
4. **Выводите прогресс-бар** - для визуальной обратной связи
5. **Обрабатывайте ошибки** - логируйте неудачные шаги
6. **Очищайте старые логи** - ротация логов по размеру/времени
