#!/bin/bash
# =============================================================================
# dispatch.sh - Gastown Task Dispatch
# =============================================================================
# Назначение: Отправка задачи агенту в worktree
#
# Использование:
#   .qwen/scripts/gastown/dispatch.sh <worktree-name> <task-spec>
#
# Пример:
#   .qwen/scripts/gastown/dispatch.sh "agent-dev-specialist-task-001" "specs/task-001"
#
# Выход:
#   Успех: task-id (stdout)
#   Ошибка: код ошибки + сообщение (stderr)
# =============================================================================

set -e

# =============================================================================
# Конфигурация
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GASTOWN_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")/gastown"
CONFIG_FILE="$GASTOWN_DIR/config.json"
REGISTRY_FILE="$GASTOWN_DIR/registry.json"
WORKTREES_DIR="$GASTOWN_DIR/worktrees"
LOGS_DIR="$GASTOWN_DIR/logs"

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# Счетчики
ERRORS=0

# =============================================================================
# Функции
# =============================================================================

error() {
    echo -e "${RED}❌ ОШИБКА:${NC} $1" >&2
    ((ERRORS++))
}

warn() {
    echo -e "${YELLOW}⚠️  ПРЕДУПРЕЖДЕНИЕ:${NC} $1" >&2
}

info() {
    echo -e "${BLUE}ℹ️  ИНФО:${NC} $1"
}

success() {
    echo -e "${GREEN}✅ УСПЕХ:${NC} $1"
}

section() {
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  $1${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
}

log_action() {
    local action="$1"
    local details="$2"
    local timestamp=$(date -Iseconds)
    echo "[$timestamp] DISPATCH: $details" >> "$LOGS_DIR/dispatch.log"
}

# Функция проверки worktree
check_worktree_exists() {
    local worktree_name="$1"
    
    section "Проверка worktree"
    
    local worktree_path="$WORKTREES_DIR/$worktree_name"
    
    if [ ! -d "$worktree_path" ]; then
        error "Worktree не найден: $worktree_path"
        info "Доступные worktree:"
        git worktree list 2>/dev/null | grep -v "^$" || echo "  (нет активных worktree)"
        return 1
    fi
    
    # Проверка через git worktree list
    if ! git worktree list 2>/dev/null | grep -q "$worktree_name"; then
        warn "Worktree '$worktree_name' не найден в git worktree list"
        warn "Возможно worktree был удален вручную"
    fi
    
    info "Worktree найден: $worktree_path"
    success "Worktree существует"
    log_action "CHECK_WORKTREE" "Found: $worktree_name"
    return 0
}

# Функция проверки состояния агента
check_agent_status() {
    local worktree_name="$1"
    local worktree_path="$WORKTREES_DIR/$worktree_name"
    
    section "Проверка состояния агента"
    
    local state_file="$worktree_path/.qwen/gastown-state.json"
    
    if [ ! -f "$state_file" ]; then
        warn "Файл состояния не найден: $state_file"
        warn "Агент может быть не инициализирован через onboard.sh"
        return 0
    fi
    
    if command -v jq &> /dev/null; then
        local status=$(jq -r '.status // "unknown"' "$state_file" 2>/dev/null)
        info "Статус агента: $status"
        
        if [ "$status" = "busy" ]; then
            local current_task=$(jq -r '.taskId // "unknown"' "$state_file" 2>/dev/null)
            warn "Агент занят задачей: $current_task"
            warn "Дождитесь завершения текущей задачи"
            return 1
        fi
        
        if [ "$status" = "error" ]; then
            warn "Агент в состоянии ошибки"
            warn "Проверьте логи агента перед отправкой новой задачи"
        fi
    fi
    
    success "Агент готов к работе"
    log_action "CHECK_AGENT" "Status: ready"
    return 0
}

# Функция валидации спецификации задачи
validate_task_spec() {
    local task_spec="$1"
    local worktree_path="$2"
    
    section "Валидация спецификации задачи"
    
    # Проверка существования спецификации
    if [ ! -d "$task_spec" ] && [ ! -f "$task_spec" ]; then
        # Попытка найти относительно корня репозитория
        local repo_root=$(git rev-parse --show-toplevel)
        if [ -d "$repo_root/$task_spec" ]; then
            task_spec="$repo_root/$task_spec"
        elif [ -d "$repo_root/.qwen/specify/$task_spec" ]; then
            task_spec="$repo_root/.qwen/specify/$task_spec"
        else
            error "Спецификация задачи не найдена: $task_spec"
            return 1
        fi
    fi
    
    info "Спецификация: $task_spec"
    
    # Проверка наличия plan файла
    local plan_file=""
    if [ -f "$task_spec/plans/phase0-plan.json" ]; then
        plan_file="$task_spec/plans/phase0-plan.json"
    elif [ -f "$task_spec/plan.json" ]; then
        plan_file="$task_spec/plan.json"
    fi
    
    if [ -n "$plan_file" ]; then
        info "План задачи: $plan_file"
        
        if command -v jq &> /dev/null; then
            if ! jq empty "$plan_file" 2>/dev/null; then
                error "Невалидный JSON в плане задачи"
                return 1
            fi
            success "План задачи валиден"
        fi
    else
        warn "План задачи не найден, продолжаем без валидации"
    fi
    
    log_action "VALIDATE_TASK" "Spec: $task_spec"
    echo "$task_spec"
    return 0
}

# Функция создания задачи
create_task() {
    local worktree_name="$1"
    local task_spec="$2"
    local worktree_path="$WORKTREES_DIR/$worktree_name"
    
    section "Создание задачи"
    
    # Генерация task-id
    local task_id="task-$(date +%Y%m%d-%H%M%S)-$$"
    local timestamp=$(date -Iseconds)
    
    info "Task ID: $task_id"
    info "Timestamp: $timestamp"
    
    # Создание директории задачи в worktree
    local task_dir="$worktree_path/.qwen/gastown/tasks/$task_id"
    mkdir -p "$task_dir"
    
    # Копирование спецификации задачи
    if [ -d "$task_spec" ]; then
        info "Копирование спецификации задачи..."
        cp -r "$task_spec"/* "$task_dir/" 2>/dev/null || true
    fi
    
    # Создание файла задачи
    local task_file="$task_dir/task.json"
    cat > "$task_file" << EOF
{
  "taskId": "$task_id",
  "agentId": "$(basename "$worktree_path" | sed 's/agent-//' | sed 's/-task-.*//')",
  "worktreeName": "$(basename "$worktree_path")",
  "worktreePath": "$worktree_path",
  "specPath": "$task_spec",
  "status": "dispatched",
  "createdAt": "$timestamp",
  "dispatchedAt": "$timestamp",
  "startedAt": null,
  "completedAt": null,
  "timeout": null,
  "result": null,
  "error": null,
  "metrics": {
    "dispatchTime": $(date +%s),
    "startTime": null,
    "endTime": null,
    "duration": null
  }
}
EOF
    
    success "Задача создана: $task_file"
    log_action "CREATE_TASK" "Created: $task_id in $worktree_name"
    
    echo "$task_id"
    return 0
}

# Функция обновления состояния агента
update_agent_state() {
    local worktree_name="$1"
    local task_id="$2"
    local worktree_path="$WORKTREES_DIR/$worktree_name"
    
    section "Обновление состояния агента"
    
    local state_file="$worktree_path/.qwen/gastown-state.json"
    
    if [ ! -f "$state_file" ]; then
        warn "Файл состояния не найден, создаем новый"
        mkdir -p "$(dirname "$state_file")"
        cat > "$state_file" << EOF
{
  "agentId": "$(basename "$worktree_path" | sed 's/agent-//' | sed 's/-task-.*//')",
  "worktreeName": "$(basename "$worktree_path")",
  "worktreePath": "$worktree_path",
  "initializedAt": "$(date -Iseconds)",
  "status": "busy",
  "taskId": "$task_id",
  "lastHeartbeat": "$(date -Iseconds)"
}
EOF
        success "Файл состояния создан"
        return 0
    fi
    
    if command -v jq &> /dev/null; then
        local temp_file=$(mktemp)
        jq --arg task "$task_id" \
           --arg status "busy" \
           --arg heartbeat "$(date -Iseconds)" \
           '.taskId = $task | .status = $status | .lastHeartbeat = $heartbeat' \
           "$state_file" > "$temp_file" && mv "$temp_file" "$state_file"
        
        success "Состояние агента обновлено"
    else
        warn "jq не установлен, пропускаем обновление состояния"
    fi
    
    log_action "UPDATE_STATE" "Agent $worktree_name -> busy, task: $task_id"
    return 0
}

# Функция обновления реестра
update_registry() {
    local worktree_name="$1"
    local task_id="$2"
    
    section "Обновление реестра"
    
    if command -v jq &> /dev/null && [ -f "$REGISTRY_FILE" ]; then
        local temp_file=$(mktemp)
        local timestamp=$(date -Iseconds)
        
        # Обновление записи о worktree
        jq --arg name "$worktree_name" \
           --arg task "$task_id" \
           --arg status "busy" \
           --arg heartbeat "$timestamp" \
           '(.worktrees[] | select(.name == $name)) |= (.taskId = $task | .status = $status | .lastHeartbeat = $heartbeat)' \
           "$REGISTRY_FILE" > "$temp_file" 2>/dev/null && mv "$temp_file" "$REGISTRY_FILE"
        
        # Добавление в активные задачи
        jq --arg task "$task_id" \
           --arg worktree "$worktree_name" \
           --arg dispatched "$timestamp" \
           '.tasks.active += [{
             "taskId": $task,
             "worktree": $worktree,
             "dispatchedAt": $dispatched,
             "status": "dispatched"
           }]' "$REGISTRY_FILE" > "$temp_file" 2>/dev/null && mv "$temp_file" "$REGISTRY_FILE"
        
        success "Реестр обновлен"
        log_action "UPDATE_REGISTRY" "Task $task_id registered"
    else
        warn "jq не установлен или реестр не найден"
    fi
    
    return 0
}

# Функция логирования вызова
log_dispatch() {
    local worktree_name="$1"
    local task_id="$2"
    local task_spec="$3"
    
    section "Логирование вызова"
    
    local log_file="$LOGS_DIR/dispatch-$(date +%Y%m%d).log"
    
    cat >> "$log_file" << EOF

================================================================================
DISPATCH EVENT
================================================================================
Timestamp:  $(date -Iseconds)
Worktree:   $worktree_name
Task ID:    $task_id
Task Spec:  $task_spec
User:       $(whoami)
Host:       $(hostname)
================================================================================
EOF
    
    info "Событие залогировано: $log_file"
    return 0
}

# Функция вывода итогов
print_summary() {
    local worktree_name="$1"
    local task_id="$2"
    local worktree_path="$WORKTREES_DIR/$worktree_name"
    
    section "Итоги отправки задачи"
    
    echo ""
    success "Задача успешно отправлена агенту!"
    echo ""
    echo "═══════════════════════════════════════════════════════════"
    echo "  Информация о задаче"
    echo "═══════════════════════════════════════════════════════════"
    echo "  Task ID:     $task_id"
    echo "  Worktree:    $worktree_name"
    echo "  Путь:        $worktree_path"
    echo "  Статус:      dispatched"
    echo "═══════════════════════════════════════════════════════════"
    echo ""
    echo "Следующие шаги:"
    echo "  1. Мониторинг: .qwen/scripts/gastown/monitor.sh $worktree_name"
    echo "  2. Статус:     .qwen/scripts/gastown/status.sh"
    echo "  3. Сбор результатов: .qwen/scripts/gastown/collect.sh $worktree_name"
    echo ""
}

# =============================================================================
# Основная логика
# =============================================================================

# Парсинг аргументов
WORKTREE_NAME=""
TASK_SPEC=""

for arg in "$@"; do
    case $arg in
        --help|-h)
            echo "Использование: $0 <worktree-name> <task-spec>"
            echo ""
            echo "Отправка задачи агенту в worktree"
            echo ""
            echo "Параметры:"
            echo "  worktree-name  Имя worktree агента"
            echo "  task-spec      Путь к спецификации задачи"
            echo ""
            echo "Примеры:"
            echo "  $0 agent-dev-specialist-task-001 specs/task-001"
            echo "  $0 agent-bug-hunner-002 .qwen/specify/bugfix-001"
            exit 0
            ;;
    esac
done

# Проверка аргументов
if [ $# -lt 2 ]; then
    error "Недостаточно аргументов"
    echo ""
    echo "Использование:"
    echo "  $0 <worktree-name> <task-spec>"
    echo ""
    echo "Пример:"
    echo "  $0 agent-dev-specialist-task-001 specs/task-001"
    exit 1
fi

WORKTREE_NAME="$1"
TASK_SPEC="$2"

echo ""
echo -e "${CYAN}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║          Gastown Dispatch - Task Assignment               ║${NC}"
echo -e "${CYAN}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""

# Запуск проверок
check_worktree_exists "$WORKTREE_NAME" || exit 1
check_agent_status "$WORKTREE_NAME" || exit 1

# Валидация спецификации
VALIDATED_SPEC=$(validate_task_spec "$TASK_SPEC" "$WORKTREES_DIR/$WORKTREE_NAME")
if [ $? -ne 0 ]; then
    error "Валидация спецификации не пройдена"
    exit 1
fi

# Создание задачи
TASK_ID=$(create_task "$WORKTREE_NAME" "$VALIDATED_SPEC")
if [ $? -ne 0 ] || [ -z "$TASK_ID" ]; then
    error "Не удалось создать задачу"
    exit 1
fi

# Обновление состояния агента
update_agent_state "$WORKTREE_NAME" "$TASK_ID"

# Обновление реестра
update_registry "$WORKTREE_NAME" "$TASK_ID"

# Логирование
log_dispatch "$WORKTREE_NAME" "$TASK_ID" "$VALIDATED_SPEC"

# Вывод итогов
print_summary "$WORKTREE_NAME" "$TASK_ID"

# Вывод task-id для использования в скриптах
echo "$TASK_ID"

if [ "$ERRORS" -gt 0 ]; then
    exit 1
fi

exit 0
