#!/bin/bash
#
# phase0-analyzer.sh
# Назначение: Анализ задач и назначение агентов (интеграция со Speckit)
# Версия: 2.0.0 (интеграция с assign-agents-to-tasks.sh)
# Блокирующая: true (требует успешного завершения)
#

set -e

# Конфигурация
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SPECS_DIR="$PROJECT_ROOT/specs"
TMP_DIR="$PROJECT_ROOT/.tmp/current"
ASSIGN_SCRIPT="$PROJECT_ROOT/.qwen/scripts/specification-tools/assign-agents-to-tasks.sh"

# Цвета
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_header() { echo -e "${CYAN}========================================${NC}"; }

# Получение SPEC_ID (из аргумента или current)
SPEC_ID="${1:-current}"
TASKS_FILE="$SPECS_DIR/$SPEC_ID/tasks.md"

log_header
echo "  Phase 0 Analyzer: Назначение агентов"
log_header
echo ""
log_info "Spec ID: $SPEC_ID"
echo ""

# ============================================
# ПРОВЕРКА ПРЕДУСЛОВИЙ
# ============================================

# Проверка наличия tasks.md
if [ ! -f "$TASKS_FILE" ]; then
    log_error "tasks.md не найден в $TASKS_FILE"
    log_error ""
    log_error "Необходимо запустить Speckit workflow:"
    log_error "  1. speckit.specify <prompt>"
    log_error "  2. speckit.plan <tech choices>"
    log_error "  3. speckit.tasks"
    log_error "  4. phase0-analyzer.sh (этот скрипт)"
    exit 1
fi
log_success "tasks.md найден"

# Проверка наличия скрипта назначения агентов
if [ ! -x "$ASSIGN_SCRIPT" ]; then
    log_error "Скрипт assign-agents-to-tasks.sh не найден или не исполняемый"
    log_error "Путь: $ASSIGN_SCRIPT"
    exit 1
fi
log_success "assign-agents-to-tasks.sh найден"

# Создание временной директории
mkdir -p "$TMP_DIR"

echo ""

# ============================================
# ЗАПУСК НАЗНАЧЕНИЯ АГЕНТОВ
# ============================================

log_info "Запуск назначения агентов..."
echo ""

# Запуск скрипта назначения
if "$ASSIGN_SCRIPT" "$SPEC_ID"; then
    log_success "Назначение агентов завершено успешно"
else
    log_error "Ошибка при назначении агентов"
    exit 1
fi

echo ""

# ============================================
# ЧТЕНИЕ ОТЧЁТА
# ============================================

REPORT_FILE="$TMP_DIR/agent-assignment-report.json"

if [ -f "$REPORT_FILE" ]; then
    log_info "Чтение отчёта..."
    echo ""
    
    # Извлечение данных из JSON (если jq доступен)
    if command -v jq &> /dev/null; then
        TOTAL=$(jq -r '.summary.total_tasks' "$REPORT_FILE")
        ASSIGNED=$(jq -r '.summary.assigned_tasks' "$REPORT_FILE")
        NEEDS_CREATION=$(jq -r '.summary.needs_creation' "$REPORT_FILE")
        
        echo "  Всего задач: $TOTAL"
        echo "  Назначено: $ASSIGNED"
        echo "  Требуют создания агентов: $NEEDS_CREATION"
        
        if [ "$NEEDS_CREATION" -gt 0 ]; then
            echo ""
            log_warning "Отсутствующие агенты:"
            jq -r '.missing_agents[]' "$REPORT_FILE" | while read -r agent; do
                echo "  - $agent"
            done
        fi
    else
        log_warning "jq не найден, вывод отчёта невозможен"
        cat "$REPORT_FILE"
    fi
else
    log_warning "Отчёт не найден: $REPORT_FILE"
fi

echo ""

# ============================================
# СОЗДАНИЕ required-agents.json
# ============================================

log_info "Создание required-agents.json..."

REQUIRED_FILE="$TMP_DIR/required-agents.json"

if command -v jq &> /dev/null && [ -f "$REPORT_FILE" ]; then
    # Преобразование отчёта в формат required-agents
    jq '{
        generated: (.timestamp // now),
        spec_id: .spec_id,
        agents: {
            orc_: [],
            work_: (.assigned_agents // []),
            needs_creation: (.missing_agents // [])
        },
        summary: .summary
    }' "$REPORT_FILE" > "$REQUIRED_FILE"
    
    log_success "required-agents.json создан"
else
    # Резервный вариант без jq
    cat > "$REQUIRED_FILE" << EOF
{
  "generated": "$(date -Iseconds)",
  "spec_id": "$SPEC_ID",
  "agents": {
    "orc_": [],
    "work_": [],
    "needs_creation": []
  },
  "summary": {
    "total_tasks": 0,
    "assigned_tasks": 0,
    "needs_creation": 0
  }
}
EOF
    log_warning "required-agents.json создан (упрощённый формат)"
fi

echo ""

# ============================================
# ПРОВЕРКА НАЛИЧИЯ АГЕНТОВ
# ============================================

log_info "Проверка наличия агентов в системе..."
echo ""

AGENTS_DIR="$PROJECT_ROOT/.qwen/agents"
AGENT_COUNT=$(find "$AGENTS_DIR" -name "*.md" 2>/dev/null | wc -l)
log_success "Найдено агентов: $AGENT_COUNT"

# Проверка доменов
log_info "Домены агентов:"
DOMAINS=$(find "$AGENTS_DIR" -name "*.md" -exec basename {} \; 2>/dev/null | sed 's/_[^_]*_[^_]*\.md$//' | sort -u | tr '\n' ',' | sed 's/,$//')
echo "  $DOMAINS"

echo ""

# ============================================
# ИТОГИ
# ============================================

log_header
echo "  Phase 0 Analyzer: Завершено"
log_header
echo ""
log_success "✅ Артефакты:"
echo "  - $TASKS_FILE (обновлён с агентами)"
echo "  - $REPORT_FILE (отчёт)"
echo "  - $REQUIRED_FILE (требуемые агенты)"
echo ""
log_success "✅ Phase 0 завершён успешно"
echo ""
log_info "Следующий шаг: speckit.implement"
