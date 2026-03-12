#!/bin/bash

# Скрипт запуска агента-специалиста по Qwen Orchestrator Kit для проверки соответствия стандартам

PROJECT_ROOT="/home/alex/MyProjects/qwen_orc_kit_ru"
SPEC_FILE="$PROJECT_ROOT/docs/help/qwen_orchestrator_kit/specification.md"
PLAN_FILE="$PROJECT_ROOT/docs/help/qwen_orchestrator_kit/plan.md"
TASKS_FILE="$PROJECT_ROOT/docs/help/qwen_orchestrator_kit/tasks.md"
LOG_FILE="$PROJECT_ROOT/logs/qwen-cli-specialist-$(date +%Y%m%d_%H%M%S).log"

# Функция для логирования
log_specialist() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

log_specialist "=== Запуск агента-специалиста по Qwen Orchestrator Kit ==="

# Проверяем наличие необходимых файлов
if [ ! -f "$SPEC_FILE" ]; then
    log_specialist "❌ Файл спецификации не найден: $SPEC_FILE"
    exit 1
fi

if [ ! -f "$PLAN_FILE" ]; then
    log_specialist "❌ Файл плана не найден: $PLAN_FILE"
    exit 1
fi

if [ ! -f "$TASKS_FILE" ]; then
    log_specialist "❌ Файл задач не найден: $TASKS_FILE"
    exit 1
fi

log_specialist "✅ Все необходимые файлы найдены"

# Запускаем проверки соответствия
log_specialist "Запуск проверки соответствия стандартам..."

# Проверяем YAML заголовки
log_specialist "Проверка YAML заголовков агентов..."
bash "$PROJECT_ROOT/scripts/validation/check-standards-compliance.sh"

# Запускаем мониторинг
log_specialist "Запуск мониторинга соответствия стандартам..."
bash "$PROJECT_ROOT/scripts/monitoring/standards-monitoring.sh"

# Проверяем документацию
log_specialist "Проверка актуальности документации..."
DOC_COUNT=$(find "$PROJECT_ROOT/docs/help/qwen_orchestrator_kit/" -name "*.md" -type f | wc -l)
log_specialist "Найдено документационных файлов: $DOC_COUNT"

# Проверяем существование агента-специалиста
if [ -f "$PROJECT_ROOT/.qwen/agents/work_dev_qwen_code_cli_specialist.md" ]; then
    log_specialist "✅ Агент-специалист найден и готов к работе"
else
    log_specialist "❌ Агент-специалист не найден"
fi

# Проверяем существование навыков
SKILL_COUNT=0
if [ -f "$PROJECT_ROOT/.qwen/skills/yaml-header-validator/SKILL.md" ]; then
    log_specialist "✅ Навык проверки YAML заголовков найден"
    ((SKILL_COUNT++))
else
    log_specialist "❌ Навык проверки YAML заголовков не найден"
fi

if [ -f "$PROJECT_ROOT/.qwen/skills/agent-structure-checker/SKILL.md" ]; then
    log_specialist "✅ Навык проверки структуры агентов найден"
    ((SKILL_COUNT++))
else
    log_specialist "❌ Навык проверки структуры агентов не найден"
fi

log_specialist "Найдено навыков: $SKILL_COUNT/2"

# Запускаем автоматическое исправление ошибок
log_specialist "Запуск автоматического исправления стандартов..."
bash "$PROJECT_ROOT/scripts/validation/fix-standards-compliance.sh"

log_specialist ""
log_specialist "=== Агент-специалист завершил проверку ==="
log_specialist "Логи доступны в: $LOG_FILE"

# Подсчитываем результаты
ERROR_LOGS=$(grep -c "❌" "$LOG_FILE")
SUCCESS_LOGS=$(grep -c "✅" "$LOG_FILE")

log_specialist ""
log_specialist "Статистика проверки:"
log_specialist "- Обнаружено проблем: $ERROR_LOGS"
log_specialist "- Успешных проверок: $SUCCESS_LOGS"

if [ $ERROR_LOGS -eq 0 ]; then
    log_specialist ""
    log_specialist "🎉 Все проверки пройдены успешно!"
    exit 0
else
    log_specialist ""
    log_specialist "⚠️  Обнаружены проблемы, требующие внимания."
    exit 1
fi