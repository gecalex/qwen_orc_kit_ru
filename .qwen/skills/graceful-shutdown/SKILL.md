---
name: graceful-shutdown
description: Корректная остановка при timeout. Сохранение прогресса, логирование состояния, генерация отчета с ошибкой и предложение fallback.
---

# Graceful Shutdown Skill

## Когда использовать
- При обнаружении timeout во время выполнения задачи
- При получении сигнала прерывания (SIGINT, SIGTERM)
- При критических ошибках, требующих остановки
- Для сохранения прогресса перед завершением

## Инструкции

### 1. Обнаружение Timeout

**Триггеры для graceful shutdown:**
- Превышение лимита времени выполнения (по умолчанию 5 минут)
- Получение сигнала прерывания от пользователя
- Критическая ошибка, блокирующая дальнейшее выполнение
- Исчерпание ресурсов (память, диск)

### 2. Сохранение Прогресса

**Перед остановкой выполните:**

```bash
# 1. Сохранить текущее состояние сессии
.qwen/scripts/orchestration-tools/save-state.sh "<task-id>"

# 2. Создать snapshot прогресса
.qwen/scripts/monitoring/create-progress-snapshot.sh "<task-id>"

# 3. Записать последние выполненные действия
echo "$(date -Iseconds): Graceful shutdown initiated" >> .qwen/logs/<task-id>.log
```

**Файлы для сохранения:**
- `.qwen/state/<task-id>-state.json` - текущее состояние
- `.qwen/logs/<task-id>-progress.log` - лог прогресса
- `.qwen/reports/<task-id>-partial-report.md` - частичный отчет

### 3. Логирование Последнего Состояния

**Формат лога состояния:**

```json
{
  "timestamp": "2026-03-21T14:30:25+03:00",
  "taskId": "<task-id>",
  "status": "interrupted",
  "reason": "timeout|signal|error",
  "phase": "<current-phase>",
  "completedSteps": ["step1", "step2"],
  "pendingSteps": ["step3", "step4"],
  "modifiedFiles": ["file1", "file2"],
  "lastAction": "description of last action",
  "recoveryPoint": ".qwen/state/<task-id>-state.json"
}
```

### 4. Генерация Отчета с Ошибкой

**Используйте навык `generate-report-header` для создания отчета:**

```markdown
# Graceful Shutdown Report: {Version}

**Статус**: ⚠️ ПРЕРВАНО (TIMEOUT)
**Продолжительность**: {время до остановки}
**Агент**: {имя-агента}
**Причина**: timeout|signal|error

## Состояние на момент остановки
- Текущая фаза: {фаза}
- Выполнено шагов: {количество}
- Осталось шагов: {количество}

## Сохраненный прогресс
- Файл состояния: {путь}
- Лог прогресса: {путь}
- Частичный отчет: {путь}

## Измененные файлы
- {список файлов с флагом [СОХРАНЕНО]}

## Рекомендации по восстановлению
1. Проверить лог ошибок: {путь}
2. Восстановить состояние: `.qwen/scripts/orchestration-tools/restore-state.sh <task-id>`
3. Повторить с контрольной точки

## Fallback опции
- Опция 1: Продолжить с последней контрольной точки
- Опция 2: Откатить изменения и начать заново
- Опция 3: Выполнить упрощенную версию задачи
```

### 5. Предложение Fallback

**После генерации отчета предложите:**

```markdown
## Доступные действия для восстановления:

### Вариант A: Продолжить с контрольной точки
\`\`\`bash
.qwen/scripts/orchestration-tools/restore-state.sh "<task-id>"
\`\`\`

### Вариант B: Откатить и начать заново
\`\`\`bash
.qwen/scripts/git/rollback-changes.sh "<task-id>"
\`\`\`

### Вариант C: Упрощенное выполнение
\`\`\`bash
.qwen/scripts/orchestration-tools/simplified-run.sh "<task-id>"
\`\`\`
```

## Формат ввода

```json
{
  "taskId": "string",
  "reason": "timeout|signal|error|resource_exhaustion",
  "currentTime": "ISO8601 timestamp",
  "startTime": "ISO8601 timestamp",
  "phase": "string",
  "completedSteps": ["array of completed steps"],
  "modifiedFiles": ["array of modified files"]
}
```

## Формат вывода

```json
{
  "status": "shutdown_complete",
  "stateSaved": "path/to/state.json",
  "reportGenerated": "path/to/report.md",
  "recoveryScript": "path/to/restore.sh",
  "fallbackOptions": ["array of options"]
}
```

## Примеры

### Пример 1: Timeout во время выполнения

**Вход:**
```json
{
  "taskId": "dev-task-123",
  "reason": "timeout",
  "currentTime": "2026-03-21T14:35:00+03:00",
  "startTime": "2026-03-21T14:30:00+03:00",
  "phase": "phase-2-execution",
  "completedSteps": ["read-plan", "analyze-code"],
  "modifiedFiles": ["src/module.py"]
}
```

**Действия:**
1. Сохранить состояние в `.qwen/state/dev-task-123-state.json`
2. Записать лог в `.qwen/logs/dev-task-123-progress.log`
3. Сгенерировать отчет в `.qwen/reports/dev-task-123-shutdown.md`
4. Предложить восстановление

### Пример 2: Прерывание пользователем

**Вход:**
```json
{
  "taskId": "test-gen-456",
  "reason": "signal",
  "currentTime": "2026-03-21T15:00:00+03:00",
  "startTime": "2026-03-21T14:55:00+03:00",
  "phase": "phase-3-validation",
  "completedSteps": ["generate-tests", "run-linter"],
  "modifiedFiles": ["tests/test_module.py"]
}
```

## Интеграция с другими навыками

- `save-session-context` - для сохранения состояния сессии
- `generate-report-header` - для генерации стандартизированного отчета
- `resume-session` - для восстановления после shutdown

## Скрипты

### .qwen/scripts/orchestration-tools/save-state.sh
```bash
#!/bin/bash
# Сохранение текущего состояния задачи
TASK_ID="$1"
STATE_FILE=".qwen/state/${TASK_ID}-state.json"
# Логика сохранения...
```

### .qwen/scripts/monitoring/create-progress-snapshot.sh
```bash
#!/bin/bash
# Создание snapshot прогресса
TASK_ID="$1"
SNAPSHOT_FILE=".qwen/logs/${TASK_ID}-snapshot.log"
# Логика snapshot...
```

## Best Practices

1. **Всегда сохраняйте состояние** перед завершением
2. **Логируйте подробно** - каждый шаг должен быть задокументирован
3. **Предлагайте fallback** - минимум 2 варианта восстановления
4. **Проверяйте целостность** сохраненных данных
5. **Очищайте временные файлы** после успешного восстановления
