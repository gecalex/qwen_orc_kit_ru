#!/bin/bash

# =============================================================================
# update-registry.sh - Обновление реестра задач
# =============================================================================
# Назначение: Автоматическое обновление task-registry.json из tasks-tdd.md
# 
# Функционал:
#   - Извлечь задачи из tasks-tdd.md
#   - Обновить task-registry.json
#   - Проверить дубликаты
#   - Проверить нумерацию
#
# Использование:
#   .qwen/scripts/task-tools/update-registry.sh
# =============================================================================

set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Переменные
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR/../.."
TASKS_FILE="$PROJECT_ROOT/.qwen/specify/tasks-tdd.md"
REGISTRY_FILE="$PROJECT_ROOT/.qwen/specify/task-registry.json"

# Функция вывода помощи
show_help() {
    echo -e "${BLUE}update-registry.sh - Обновление реестра задач${NC}"
    echo ""
    echo "Использование:"
    echo "  $0"
    echo ""
    echo "Описание:"
    echo "  Автоматически обновляет task-registry.json из tasks-tdd.md"
    echo "  Без hardcode - универсально для любого проекта"
}

# Функция логирования
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Проверка наличия jq
check_jq() {
    if ! command -v jq &> /dev/null; then
        log_error "jq не установлен. Установите: sudo apt install jq"
        exit 1
    fi
}

# Проверка наличия tasks-tdd.md
check_tasks_file() {
    if [ ! -f "$TASKS_FILE" ]; then
        log_error "Файл задач не найден: $TASKS_FILE"
        exit 1
    fi
    log_success "tasks-tdd.md найден"
}

# Проверка наличия registry
check_registry_file() {
    if [ ! -f "$REGISTRY_FILE" ]; then
        log_warning "task-registry.json не найден. Создаём..."
        # Создать шаблон
        cat > "$REGISTRY_FILE" << 'EOF'
{
  "version": "1.0",
  "created": "{{DATE}}",
  "source_of_truth": "tasks-tdd.md",
  "description": "Реестр задач для отслеживания выполнения (универсальный шаблон)",
  "tasks": {},
  "warnings": [],
  "metadata": {
    "project_type": "any",
    "module_pattern": "T-XXX-XXX",
    "auto_generated": true,
    "template": true
  }
}
EOF
        log_success "task-registry.json создан"
    fi
}

# Извлечь задачи из tasks-tdd.md
extract_tasks() {
    log_info "Извлечение задач из tasks-tdd.md..."
    
    # Извлечь строки с задачами (формат: | T-XXX-XXX | ...)
    local tasks=$(grep -E "^\|\s*T-[0-9]+-[0-9]+" "$TASKS_FILE" | while IFS='|' read -r id type title agent hours deps rest; do
        # Очистить поля
        id=$(echo "$id" | tr -d ' ')
        title=$(echo "$title" | tr -d ' ' | sed 's/^/"/' | sed 's/$/"/')
        agent=$(echo "$agent" | tr -d ' ')
        hours=$(echo "$hours" | tr -d ' ')
        
        # Создать JSON объект
        echo "{\"id\": $id, \"title\": $title, \"agent\": $agent, \"hours\": $hours, \"status\": \"pending\"}"
    done | jq -s '.')
    
    if [ -z "$tasks" ] || [ "$tasks" = "[]" ]; then
        log_error "Задачи не найдены в tasks-tdd.md"
        exit 1
    fi
    
    log_success "Извлечено $(echo "$tasks" | jq 'length') задач"
    
    echo "$tasks"
}

# Обновить registry
update_registry() {
    local tasks="$1"
    
    log_info "Обновление task-registry.json..."
    
    # Обновить задачи
    jq --argjson tasks "$tasks" --arg date "$(date -Iseconds)" '
      .tasks = ($tasks | map({(.id): .}) | add) |
      .metadata.last_updated = $date
    ' "$REGISTRY_FILE" > "${REGISTRY_FILE}.tmp"
    
    mv "${REGISTRY_FILE}.tmp" "$REGISTRY_FILE"
    
    log_success "task-registry.json обновлён"
}

# Проверить дубликаты
check_duplicates() {
    log_info "Проверка дубликатов..."
    
    local duplicates=$(jq -r '.tasks | keys[]' "$REGISTRY_FILE" | sort | uniq -d)
    
    if [ -n "$duplicates" ]; then
        log_warning "Обнаружены дубликаты: $duplicates"
        jq --arg dups "$duplicates" '.warnings += [{"type": "duplicate", "message": "Дубликаты: \($dups)"}]' "$REGISTRY_FILE" > "${REGISTRY_FILE}.tmp"
        mv "${REGISTRY_FILE}.tmp" "$REGISTRY_FILE"
    else
        log_success "Дубликаты не найдены"
    fi
}

# Проверить нумерацию
check_numbering() {
    log_info "Проверка нумерации..."
    
    # Извлечь все номера задач
    local task_ids=$(jq -r '.tasks | keys[]' "$REGISTRY_FILE" | sort)
    
    # Проверить последовательность
    local prev_module=""
    local prev_task=0
    local warnings=()
    
    for task_id in $task_ids; do
        # Извлечь модуль и номер (T-XXX-XXX)
        local module=$(echo "$task_id" | cut -d'-' -f2)
        local task=$(echo "$task_id" | cut -d'-' -f3)
        
        # Проверить последовательность
        if [ "$module" = "$prev_module" ]; then
            if [ "$task" -le "$prev_task" ]; then
                warnings+=("Нарушена последовательность: $task_id после T-${prev_module}-${prev_task}")
            fi
        fi
        
        prev_module="$module"
        prev_task="$task"
    done
    
    if [ ${#warnings[@]} -gt 0 ]; then
        log_warning "Обнаружены проблемы с нумерацией:"
        printf '%s\n' "${warnings[@]}"
    else
        log_success "Нумерация корректна"
    fi
}

# Основная функция
main() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  Обновление реестра задач${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
    
    # Проверки
    check_jq
    check_tasks_file
    check_registry_file
    
    # Извлечь задачи
    local tasks=$(extract_tasks)
    
    # Обновить registry
    update_registry "$tasks"
    
    # Проверки
    check_duplicates
    check_numbering
    
    echo ""
    echo -e "${GREEN}✅ Реестр задач обновлён${NC}"
    echo ""
    echo "Файл: $REGISTRY_FILE"
}

# Запуск
main "$@"
