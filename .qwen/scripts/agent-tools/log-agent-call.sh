#!/bin/bash
# Скрипт: .qwen/scripts/agent-tools/log-agent-call.sh
# Назначение: Журнал вызовов агентов для аудита и отслеживания выполнения задач
# Использование: .qwen/scripts/agent-tools/log-agent-call.sh <AGENT_NAME> <TASK_ID> [STATUS] [NOTES]

set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Проверка аргументов
if [ $# -lt 2 ]; then
    echo "Использование: $0 <AGENT_NAME> <TASK_ID> [STATUS] [NOTES]"
    echo ""
    echo "Аргументы:"
    echo "  AGENT_NAME  - Имя агента (например, orc_dev_task_coordinator)"
    echo "  TASK_ID     - ID задачи (например, P0-T01)"
    echo "  STATUS      - Статус (started, completed, failed, delegated)"
    echo "  NOTES       - Заметки (опционально)"
    echo ""
    echo "Примеры:"
    echo "  $0 orc_planning_task_analyzer P0-T01 started"
    echo "  $0 work_dev_code_analyzer P0-T02 completed \"Код написан\""
    exit 1
fi

AGENT_NAME="$1"
TASK_ID="$2"
STATUS="${3:-started}"
NOTES="${4:-}"

# Директория для логов
LOGS_DIR=".qwen/logs"
LOG_FILE="$LOGS_DIR/agent-calls.log"
REPORTS_DIR=".qwen/reports/agent-calls"

# Создание директорий
if [ ! -d "$LOGS_DIR" ]; then
    mkdir -p "$LOGS_DIR"
    log_info "Создана директория: $LOGS_DIR"
fi

if [ ! -d "$REPORTS_DIR" ]; then
    mkdir -p "$REPORTS_DIR"
    log_info "Создана директория: $REPORTS_DIR"
fi

#Timestamp
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
DATE=$(date '+%Y-%m-%d')

# Формирование записи лога
LOG_ENTRY="$TIMESTAMP | $AGENT_NAME | $TASK_ID | $STATUS | $NOTES"

# Запись в общий лог
echo "$LOG_ENTRY" >> "$LOG_FILE"

# Запись в ежедневный отчет
DAILY_REPORT="$REPORTS_DIR/calls-$DATE.md"

if [ ! -f "$DAILY_REPORT" ]; then
    cat > "$DAILY_REPORT" << EOF
# Журнал вызовов агентов: $DATE

**Создано:** $TIMESTAMP

| Время | Агент | Задача | Статус | Заметки |
|-------|-------|--------|--------|---------|
EOF
fi

# Добавление записи в ежедневный отчет
echo "| $TIMESTAMP | $AGENT_NAME | $TASK_ID | $STATUS | $NOTES |" >> "$DAILY_REPORT"

# Вывод результата
echo ""
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║  Запись вызова агента сохранена                          ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""
log_success "Агент: $AGENT_NAME"
log_info "Задача: $TASK_ID"
log_info "Статус: $STATUS"

if [ -n "$NOTES" ]; then
    log_info "Заметки: $NOTES"
fi

echo ""
echo "📄 Лог файл: $LOG_FILE"
echo "📄 Дневной отчет: $DAILY_REPORT"
echo ""

# Статистика за сегодня
TODAY_COUNT=$(grep -c "^$DATE" "$LOG_FILE" 2>/dev/null || echo 0)
log_info "Всего вызовов сегодня: $TODAY_COUNT"

# Статистика по агенту
AGENT_COUNT=$(grep -c "| $AGENT_NAME |" "$LOG_FILE" 2>/dev/null || echo 0)
log_info "Всего вызовов агента: $AGENT_COUNT"

echo ""

# Проверка на дублирование вызовов (предупреждение)
DUPLICATE_COUNT=$(grep "| $AGENT_NAME | $TASK_ID |" "$LOG_FILE" | wc -l)
if [ "$DUPLICATE_COUNT" -gt 1 ]; then
    log_warning "Агент $AGENT_NAME вызван для задачи $TASK_ID повторно ($DUPLICATE_COUNT раз)"
    echo ""
fi

exit 0
