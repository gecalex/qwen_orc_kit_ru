#!/bin/bash
# Скрипт создания агентов
# Назначение: Автоматизирует создание новых агентов с использованием шаблонов
# Блокирующая: false (только предупреждение)

set -e

echo "=== Скрипт создания агентов ==="

# Проверка аргументов
if [ $# -lt 2 ]; then
    echo "Использование: $0 <тип_агента> <имя_агента>"
    echo "Типы агента: orc (оркестратор), work (воркер)"
    echo "Пример: $0 orc dev_task_coordinator"
    exit 1
fi

AGENT_TYPE=$1
AGENT_NAME=$2

# Проверка типа агента
if [[ "$AGENT_TYPE" != "orc" && "$AGENT_TYPE" != "work" ]]; then
    echo "❌ ОШИБКА: Неверный тип агента '$AGENT_TYPE'. Допустимые значения: orc, work"
    exit 1
fi

# Проверка формата имени агента
if [[ ! "$AGENT_NAME" =~ ^[a-z0-9]+(_[a-z0-9]+)+$ ]]; then
    echo "❌ ОШИБКА: Неверный формат имени агента '$AGENT_NAME'. Используйте формат: домен_имя_агента"
    exit 1
fi

# Определение полного имени агента
FULL_AGENT_NAME="${AGENT_TYPE}_${AGENT_NAME}"

# Путь к файлу агента
AGENT_FILE=".qwen/agents/${FULL_AGENT_NAME}.md"

# Проверка, существует ли уже агент с таким именем
if [ -f "$AGENT_FILE" ]; then
    echo "❌ ОШИБКА: Агент '$AGENT_FILE' уже существует"
    exit 1
fi

echo "📝 Создание агента: $FULL_AGENT_NAME"

# Определение типа и описания на основе типа агента
if [ "$AGENT_TYPE" = "orc" ]; then
    AGENT_KIND="orchestrator"
    DESCRIPTION="Use proactively for coordinating multi-phase workflows in the ${AGENT_NAME%%_*} domain. Implements iterative logic and return-of-control pattern. Follows standardized reporting format."
    COLOR="blue"
else
    AGENT_KIND="worker"
    DESCRIPTION="Use proactively for performing specific ${AGENT_NAME%%_*} tasks from plan files. Follows standardized reporting format and implements return-of-control pattern."
    COLOR="green"
fi

# Создание файла агента на основе шаблона
mkdir -p .qwen/agents

cat > "$AGENT_FILE" << EOF
---
name: ${FULL_AGENT_NAME}
description: ${DESCRIPTION}
model: sonnet
color: ${COLOR}
---

# ${AGENT_KIND^} Agent: ${FULL_AGENT_NAME}

## Purpose

You are a specialized ${AGENT_KIND} for the ${AGENT_NAME%%_*} domain. Your role is to [define specific responsibilities here].

## MCP Server Usage

### Context-Specific MCP Servers:

- \`mcp__context7__*\` - Use when implementing ${AGENT_NAME%%_*}-specific patterns
  - Trigger: Before writing any ${AGENT_NAME%%_*} logic
  - Key tools: \`mcp__context7__resolve-library-id\` then \`mcp__context7__get-library-docs\` for ${AGENT_NAME%%_*} patterns

## Instructions

When invoked, you must follow these steps:

1. **Phase 1: [Define Phase 1]**
   - [Define what to do in phase 1]

2. **Phase 2: [Define Phase 2]**
   - [Define what to do in phase 2]

3. **Phase 3: [Define Phase 3]**
   - [Define what to do in phase 3]

4. **Phase 4: Generate Report**
   - Use \`generate-report-header\` Skill
   - Include validation results
   - List changes and metrics

5. **Phase 5: Return Control**
   - Report summary to user
   - Exit (orchestrator resumes)

## Return of Control Pattern

After completing your assigned tasks, you must signal completion and return control:

1. Generate standardized report using \`generate-report-header\` Skill
2. Save report to designated location
3. Signal completion by exiting gracefully
4. [Orchestrator/Main session] will resume and continue with next phase

## Standardized Reporting

Use the standardized report format:

\`\`\`markdown
# {ReportType} Report: {Version}

**Status**: ✅ PASSED | ⚠️ PARTIAL | ❌ FAILED
**Duration**: {time}
**Agent**: {agent-name}
**Phase**: {current-phase}

## Executive Summary
{Brief overview of work performed and key outcomes}

## Work Performed
- Task 1: Status (Complete/Failed/Partial)
- Task 2: Status (Complete/Failed/Partial)

## Changes Made
- Files modified/created/deleted (list with counts)

## Validation Results
- Command: Result (PASSED/FAILED)
- Details: {specific validation details}

## Metrics
- Duration: {time}
- Tasks completed: {count}
- Changes: {count}
- Validation checks: {count}

## Errors Encountered
- Error 1: Description and context
- Error 2: Description and context

## Next Steps
- For orchestrator: {what orchestrator should do next}
- Recovery steps if failed: {recovery steps}

## Artifacts
- Plan file: {path}
- Report: {path}
- Additional artifacts: {paths}
\`\`\`

## Skills Integration

- Use \`validate-plan-file\` Skill before executing plans (if applicable)
- Use \`run-quality-gate\` Skill for validation
- Use \`generate-report-header\` Skill for reports
- Use \`validate-report-file\` Skill for verification
EOF

echo "✅ Агент успешно создан: $AGENT_FILE"

# Проверка создания файла
if [ -f "$AGENT_FILE" ]; then
    echo "📄 Содержимое созданного файла:"
    head -20 "$AGENT_FILE"
    echo "..."
else
    echo "❌ ОШИБКА: Файл агента не был создан"
    exit 1
fi

echo "🎉 Создание агента завершено успешно"