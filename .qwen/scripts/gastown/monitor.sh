#!/bin/bash
# =============================================================================
# monitor.sh - Gastown Task Monitoring
# =============================================================================
# Назначение: Мониторинг активных задач и worktree
#
# Использование:
#   .qwen/scripts/gastown/monitor.sh [worktree-name]
#
# Пример:
#   .qwen/scripts/gastown/monitor.sh                          # Все worktree
#   .qwen/scripts/gastown/monitor.sh agent-dev-specialist     # Конкретный worktree
#
# Выход:
#   Успех: статус мониторинга (stdout)
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
METRICS_DIR="$GASTOWN_DIR/metrics"

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
WHITE='\033[1;37m'
NC='\033[0m'

# Счетчики
ERRORS=0
WARNINGS=0

# =============================================================================
# Функции
# =============================================================================

error() {
    echo -e "${RED}❌ ОШИБКА:${NC} $1" >&2
    ((ERRORS++))
}

warn() {
    echo -e "${YELLOW}⚠️  ПРЕДУПРЕЖДЕНИЕ:${NC} $1" >&2
    ((WARNINGS++))
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
    echo "[$timestamp] MONITOR: $details" >> "$LOGS_DIR/monitor.log"
}

# Функция получения конфигурации timeout
get_timeout_config() {
    local timeout_type="${1:-default}"
    
    if command -v jq &> /dev/null && [ -f "$CONFIG_FILE" ]; then
        jq -r ".timeout.task.$timeout_type // 3600" "$CONFIG_FILE" 2>/dev/null
    else
        echo "3600"
    fi
}

# Функция проверки worktree
check_worktree_health() {
    local worktree_name="$1"
    local worktree_path="$WORKTREES_DIR/$worktree_name"
    
    # Проверка существования
    if [ ! -d "$worktree_path" ]; then
        echo -e "${RED}OFFLINE${NC}"
        return 1
    fi
    
    # Проверка через git
    if ! git worktree list 2>/dev/null | grep -q "$worktree_name"; then
        echo -e "${YELLOW}DETACHED${NC}"
        return 0
    fi
    
    # Проверка состояния агента
    local state_file="$worktree_path/.qwen/gastown-state.json"
    if [ -f "$state_file" ] && command -v jq &> /dev/null; then
        local status=$(jq -r '.status // "unknown"' "$state_file" 2>/dev/null)
        local last_heartbeat=$(jq -r '.lastHeartbeat // "unknown"' "$state_file" 2>/dev/null)
        
        case "$status" in
            "active"|"idle")
                echo -e "${GREEN}IDLE${NC}"
                ;;
            "busy"|"running")
                echo -e "${CYAN}RUNNING${NC}"
                ;;
            "error"|"failed")
                echo -e "${RED}ERROR${NC}"
                ;;
            "collected")
                echo -e "${MAGENTA}COLLECTED${NC}"
                ;;
            *)
                echo -e "${WHITE}$status${NC}"
                ;;
        esac
    else
        echo -e "${WHITE}UNKNOWN${NC}"
    fi
    
    return 0
}

# Функция проверки timeout задачи
check_task_timeout() {
    local worktree_path="$1"
    local task_id="$2"
    
    local task_file="$worktree_path/.qwen/gastown/tasks/$task_id/task.json"
    
    if [ ! -f "$task_file" ]; then
        return 0
    fi
    
    if command -v jq &> /dev/null; then
        local status=$(jq -r '.status // "unknown"' "$task_file" 2>/dev/null)
        local dispatched=$(jq -r '.dispatchedAt // .createdAt // ""' "$task_file" 2>/dev/null)
        
        if [ "$status" = "running" ] || [ "$status" = "dispatched" ]; then
            if [ -n "$dispatched" ]; then
                local dispatched_ts=$(date -d "$dispatched" +%s 2>/dev/null || echo "0")
                local current_ts=$(date +%s)
                local elapsed=$((current_ts - dispatched_ts))
                local timeout=$(get_timeout_config "default")
                
                if [ "$elapsed" -gt "$timeout" ]; then
                    echo -e "${RED}TIMEOUT${NC} (${elapsed}s > ${timeout}s)"
                    return 1
                fi
                
                local remaining=$((timeout - elapsed))
                echo -e "${YELLOW}${remaining}s${NC}"
            fi
        fi
    fi
    
    echo -e "${GREEN}OK${NC}"
    return 0
}

# Функция получения списка worktree
list_worktrees() {
    section "Активные Worktree"
    
    if [ ! -d "$WORKTREES_DIR" ]; then
        warn "Директория worktree не найдена: $WORKTREES_DIR"
        return 0
    fi
    
    local worktrees=$(ls -1 "$WORKTREES_DIR" 2>/dev/null)
    
    if [ -z "$worktrees" ]; then
        info "Нет активных worktree"
        return 0
    fi
    
    echo ""
    printf "${WHITE}%-40s %-15s %-20s %-15s${NC}\n" "WORKTREE" "STATUS" "LAST HEARTBEAT" "TIMEOUT"
    printf "${WHITE}%s${NC}\n" "────────────────────────────────────────────────────────────────────────────"
    
    local count=0
    local running=0
    local idle=0
    local errors=0
    
    for worktree in $worktrees; do
        local worktree_path="$WORKTREES_DIR/$worktree"
        local status=$(check_worktree_health "$worktree")
        
        # Получение last heartbeat
        local state_file="$worktree_path/.qwen/gastown-state.json"
        local heartbeat="N/A"
        if [ -f "$state_file" ] && command -v jq &> /dev/null; then
            heartbeat=$(jq -r '.lastHeartbeat // "N/A"' "$state_file" 2>/dev/null | cut -c1-19)
        fi
        
        # Проверка timeout
        local timeout_status=$(check_task_timeout "$worktree_path" "")
        
        printf "%-40b %-15b %-20s " "$worktree" "$status" "$heartbeat"
        echo -e "$timeout_status"
        
        ((count++))
        
        if [[ "$status" == *"RUNNING"* ]]; then
            ((running++))
        elif [[ "$status" == *"IDLE"* ]]; then
            ((idle++))
        elif [[ "$status" == *"ERROR"* ]] || [[ "$status" == *"OFFLINE"* ]]; then
            ((errors++))
        fi
    done
    
    echo ""
    echo "═══════════════════════════════════════════════════════════"
    echo "  Всего: $count | Running: $running | Idle: $idle | Errors: $errors"
    echo "═══════════════════════════════════════════════════════════"
    
    log_action "LIST_WORKTREES" "Total: $count, Running: $running, Idle: $idle, Errors: $errors"
    return 0
}

# Функция мониторинга конкретной задачи
monitor_task() {
    local worktree_name="$1"
    local worktree_path="$WORKTREES_DIR/$worktree_name"
    
    section "Мониторинг задачи: $worktree_name"
    
    local tasks_dir="$worktree_path/.qwen/gastown/tasks"
    
    if [ ! -d "$tasks_dir" ]; then
        info "Задачи не найдены"
        return 0
    fi
    
    for task_dir in "$tasks_dir"/*/; do
        if [ -d "$task_dir" ]; then
            local task_id=$(basename "$task_dir")
            local task_file="$task_dir/task.json"
            
            echo ""
            info "Задача: $task_id"
            
            if [ -f "$task_file" ] && command -v jq &> /dev/null; then
                local status=$(jq -r '.status // "unknown"' "$task_file")
                local created=$(jq -r '.createdAt // "N/A"' "$task_file" | cut -c1-25)
                local completed=$(jq -r '.completedAt // "N/A"' "$task_file" | cut -c1-25)
                
                echo "  Статус:     $status"
                echo "  Создана:    $created"
                echo "  Завершена:  $completed"
                
                # Проверка timeout
                if [ "$status" = "running" ] || [ "$status" = "dispatched" ]; then
                    local timeout_status=$(check_task_timeout "$worktree_path" "$task_id")
                    echo "  Timeout:    $timeout_status"
                fi
            else
                echo "  (информация недоступна)"
            fi
        fi
    done
    
    return 0
}

# Функция проверки использования ресурсов
check_resource_usage() {
    section "Использование ресурсов"
    
    # Проверка дискового пространства
    local gastown_size=$(du -sh "$GASTOWN_DIR" 2>/dev/null | cut -f1)
    info "Gastown directory: $gastown_size"
    
    # Проверка worktree размеров
    if [ -d "$WORKTREES_DIR" ]; then
        echo ""
        info "Размеры worktree:"
        for worktree in "$WORKTREES_DIR"/*/; do
            if [ -d "$worktree" ]; then
                local name=$(basename "$worktree")
                local size=$(du -sh "$worktree" 2>/dev/null | cut -f1)
                printf "  %-40s %s\n" "$name" "$size"
            fi
        done
    fi
    
    # Проверка лимитов из конфигурации
    if command -v jq &> /dev/null && [ -f "$CONFIG_FILE" ]; then
        local max_disk=$(jq -r '.resources.maxDiskUsageMB // 10240' "$CONFIG_FILE")
        info ""
        info "Лимиты конфигурации:"
        echo "  Max Disk Usage: ${max_disk}MB"
    fi
    
    log_action "CHECK_RESOURCES" "Gastown size: $gastown_size"
    return 0
}

# Функция проверки проблем и предупреждений
check_issues() {
    section "Проблемы и предупреждения"
    
    local issues_found=0
    
    # Проверка на старые worktree
    if [ -d "$WORKTREES_DIR" ]; then
        local prune_days=$(jq -r '.worktree.pruneAfterDays // 7' "$CONFIG_FILE" 2>/dev/null || echo "7")
        local prune_threshold=$(date -d "$prune_days days ago" +%s 2>/dev/null || echo "0")
        
        for worktree_dir in "$WORKTREES_DIR"/*/; do
            if [ -d "$worktree_dir" ]; then
                local state_file="$worktree_dir/.qwen/gastown-state.json"
                if [ -f "$state_file" ] && command -v jq &> /dev/null; then
                    local initialized=$(jq -r '.initializedAt // ""' "$state_file" 2>/dev/null)
                    if [ -n "$initialized" ]; then
                        local init_ts=$(date -d "$initialized" +%s 2>/dev/null || echo "0")
                        if [ "$init_ts" -lt "$prune_threshold" ]; then
                            warn "Старый worktree: $(basename "$worktree_dir") (>$prune_days дней)"
                            ((issues_found++))
                        fi
                    fi
                fi
            fi
        done
    fi
    
    # Проверка на задачи в состоянии timeout
    if [ -d "$WORKTREES_DIR" ]; then
        for worktree_dir in "$WORKTREES_DIR"/*/; do
            if [ -d "$worktree_dir" ]; then
                local tasks_dir="$worktree_dir/.qwen/gastown/tasks"
                if [ -d "$tasks_dir" ]; then
                    for task_dir in "$tasks_dir"/*/; do
                        if [ -d "$task_dir" ]; then
                            local task_file="$task_dir/task.json"
                            if [ -f "$task_file" ] && command -v jq &> /dev/null; then
                                local status=$(jq -r '.status // ""' "$task_file")
                                if [ "$status" = "running" ] || [ "$status" = "dispatched" ]; then
                                    local timeout_status=$(check_task_timeout "$worktree_dir" "")
                                    if [[ "$timeout_status" == *"TIMEOUT"* ]]; then
                                        error "Task timeout: $(basename "$task_dir")"
                                        ((issues_found++))
                                    fi
                                fi
                            fi
                        fi
                    done
                fi
            fi
        done
    fi
    
    # Проверка реестра
    if [ -f "$REGISTRY_FILE" ] && command -v jq &> /dev/null; then
        local health_status=$(jq -r '.health.status // "unknown"' "$REGISTRY_FILE" 2>/dev/null)
        if [ "$health_status" = "degraded" ] || [ "$health_status" = "critical" ]; then
            warn "Health status реестра: $health_status"
            ((issues_found++))
        fi
    fi
    
    if [ "$issues_found" -eq 0 ]; then
        success "Проблем не обнаружено"
    else
        echo ""
        warn "Всего проблем: $issues_found"
    fi
    
    log_action "CHECK_ISSUES" "Issues found: $issues_found"
    return 0
}

# Функция вывода статуса реестра
show_registry_status() {
    section "Статус реестра"
    
    if [ ! -f "$REGISTRY_FILE" ]; then
        warn "Файл реестра не найден"
        return 0
    fi
    
    if command -v jq &> /dev/null; then
        local stats=$(jq '.statistics' "$REGISTRY_FILE" 2>/dev/null)
        
        if [ "$stats" != "null" ] && [ -n "$stats" ]; then
            local total_worktrees=$(jq -r '.totalWorktreesCreated // 0' "$REGISTRY_FILE")
            local total_tasks=$(jq -r '.totalTasksDispatched // 0' "$REGISTRY_FILE")
            local completed=$(jq -r '.totalTasksCompleted // 0' "$REGISTRY_FILE")
            local failed=$(jq -r '.totalTasksFailed // 0' "$REGISTRY_FILE")
            local success_rate=$(jq -r '.successRate // 0' "$REGISTRY_FILE")
            
            echo ""
            echo "  Worktrees создано:  $total_worktrees"
            echo "  Задач отправлено:   $total_tasks"
            echo "  Задач завершено:    $completed"
            echo "  Задач с ошибками:   $failed"
            echo "  Success Rate:       ${success_rate}%"
        else
            info "Статистика недоступна"
        fi
        
        local health=$(jq -r '.health.status // "unknown"' "$REGISTRY_FILE")
        local last_check=$(jq -r '.health.lastCheck // "N/A"' "$REGISTRY_FILE" | cut -c1-25)
        
        echo ""
        echo "  Health Status: $health"
        echo "  Last Check:    $last_check"
    else
        info "jq не установлен"
    fi
    
    log_action "SHOW_REGISTRY" "Registry status displayed"
    return 0
}

# Функция live мониторинга (опция --watch)
watch_mode() {
    local interval="${1:-30}"
    
    info "Запуск live мониторинга (интервал: ${interval}s)"
    info "Нажмите Ctrl+C для остановки"
    echo ""
    
    while true; do
        clear
        echo "═══════════════════════════════════════════════════════════"
        echo "  Gastown Monitor - Live View (Ctrl+C to exit)"
        echo "  Updated: $(date)"
        echo "═══════════════════════════════════════════════════════════"
        
        list_worktrees
        check_issues
        
        sleep "$interval"
    done
}

# =============================================================================
# Основная логика
# =============================================================================

# Парсинг аргументов
WORKTREE_NAME=""
WATCH_MODE=false
WATCH_INTERVAL=30

for arg in "$@"; do
    case $arg in
        --help|-h)
            echo "Использование: $0 [worktree-name] [options]"
            echo ""
            echo "Мониторинг активных задач и worktree"
            echo ""
            echo "Параметры:"
            echo "  worktree-name     Имя worktree для мониторинга (опционально)"
            echo "  --watch           Live мониторинг с автообновлением"
            echo "  --interval N      Интервал обновления в секундах (по умолчанию: 30)"
            echo ""
            echo "Примеры:"
            echo "  $0                              # Все worktree"
            echo "  $0 agent-dev-specialist         # Конкретный worktree"
            echo "  $0 --watch --interval 10        # Live мониторинг"
            exit 0
            ;;
        --watch|-w)
            WATCH_MODE=true
            ;;
        --interval|-i)
            WATCH_INTERVAL="${2:-30}"
            shift
            ;;
    esac
done

# Если первый аргумент не опция, это worktree name
if [ -n "$1" ] && [[ ! "$1" =~ ^- ]]; then
    WORKTREE_NAME="$1"
fi

echo ""
echo -e "${CYAN}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║          Gastown Monitor - Task Monitoring                ║${NC}"
echo -e "${CYAN}╚═══════════════════════════════════════════════════════════╝${NC}"

# Запуск в режиме watch
if [ "$WATCH_MODE" = true ]; then
    watch_mode "$WATCH_INTERVAL"
    exit 0
fi

# Мониторинг конкретного worktree
if [ -n "$WORKTREE_NAME" ]; then
    if [ ! -d "$WORKTREES_DIR/$WORKTREE_NAME" ]; then
        error "Worktree не найден: $WORKTREE_NAME"
        exit 1
    fi
    monitor_task "$WORKTREE_NAME"
else
    # Общий мониторинг
    list_worktrees
    show_registry_status
    check_resource_usage
    check_issues
fi

log_action "MONITOR_COMPLETE" "Monitoring completed"

if [ "$ERRORS" -gt 0 ]; then
    exit 1
fi

exit 0
