#!/bin/bash
# =============================================================================
# witness.sh - Gastown Agent Health Monitor
# =============================================================================
# Назначение: Мониторинг здоровья агентов, detection зависаний, auto-restart
#
# Использование:
#   .qwen/scripts/gastown/witness.sh [options]
#
# Пример:
#   .qwen/scripts/gastown/witness.sh --watch --auto-restart
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
WHITE='\033[1;37m'
NC='\033[0m'

# Эмодзи статусов
STATUS_HEALTHY="🟢"
STATUS_WARNING="🟡"
STATUS_CRITICAL="🔴"
STATUS_DEAD="⚫"

# Счетчики
ERRORS=0
WARNINGS=0
HEALTHY_COUNT=0
WARNING_COUNT=0
CRITICAL_COUNT=0
DEAD_COUNT=0
RESTARTED_COUNT=0

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
    echo "[$timestamp] WITNESS: $details" >> "$LOGS_DIR/witness.log"
}

# Функция получения порогов из конфигурации
get_threshold() {
    local key="$1"
    local default="$2"
    
    if command -v jq &> /dev/null && [ -f "$CONFIG_FILE" ]; then
        jq -r ".witness.thresholds.$key // $default" "$CONFIG_FILE" 2>/dev/null || echo "$default"
    else
        echo "$default"
    fi
}

# Функция проверки heartbeat
check_heartbeat() {
    local state_file="$1"
    
    if [ ! -f "$state_file" ]; then
        echo "dead"
        return
    fi
    
    if ! command -v jq &> /dev/null; then
        echo "unknown"
        return
    fi
    
    local last_heartbeat=$(jq -r '.lastHeartbeat // ""' "$state_file" 2>/dev/null)
    
    if [ -z "$last_heartbeat" ]; then
        echo "dead"
        return
    fi
    
    local heartbeat_ts=$(date -d "$last_heartbeat" +%s 2>/dev/null || echo "0")
    local current_ts=$(date +%s)
    local diff=$((current_ts - heartbeat_ts))
    
    local warning_threshold=$(get_threshold "heartbeatWarning" "120")
    local critical_threshold=$(get_threshold "heartbeatCritical" "300")
    local dead_threshold=$(get_threshold "heartbeatDead" "600")
    
    if [ "$diff" -gt "$dead_threshold" ]; then
        echo "dead"
    elif [ "$diff" -gt "$critical_threshold" ]; then
        echo "critical"
    elif [ "$diff" -gt "$warning_threshold" ]; then
        echo "warning"
    else
        echo "healthy"
    fi
}

# Функция проверки статуса задачи
check_task_status() {
    local worktree_path="$1"
    local tasks_dir="$worktree_path/.qwen/gastown/tasks"
    
    if [ ! -d "$tasks_dir" ]; then
        echo "idle"
        return
    fi
    
    local latest_task=$(ls -td "$tasks_dir"/*/ 2>/dev/null | head -n1 | sed 's/\/$//')
    
    if [ -z "$latest_task" ]; then
        echo "idle"
        return
    fi
    
    local task_file="$latest_task/task.json"
    
    if [ ! -f "$task_file" ]; then
        echo "unknown"
        return
    fi
    
    if command -v jq &> /dev/null; then
        local status=$(jq -r '.status // "unknown"' "$task_file" 2>/dev/null)
        local timeout_config=$(get_threshold "taskTimeout" "3600")
        
        # Проверка на timeout
        if [ "$status" = "running" ] || [ "$status" = "dispatched" ]; then
            local dispatched=$(jq -r '.dispatchedAt // .createdAt // ""' "$task_file" 2>/dev/null)
            if [ -n "$dispatched" ]; then
                local dispatched_ts=$(date -d "$dispatched" +%s 2>/dev/null || echo "0")
                local current_ts=$(date +%s)
                local elapsed=$((current_ts - dispatched_ts))
                
                if [ "$elapsed" -gt "$timeout_config" ]; then
                    echo "timeout"
                    return
                fi
            fi
        fi
        
        echo "$status"
    else
        echo "unknown"
    fi
}

# Функция определения общего статуса агента
get_agent_status() {
    local worktree_path="$1"
    local state_file="$worktree_path/.qwen/gastown-state.json"
    
    # Проверка heartbeat
    local heartbeat_status=$(check_heartbeat "$state_file")
    
    # Проверка статуса задачи
    local task_status=$(check_task_status "$worktree_path")
    
    # Определение итогового статуса
    if [ "$heartbeat_status" = "dead" ]; then
        echo "dead"
    elif [ "$heartbeat_status" = "critical" ] || [ "$task_status" = "timeout" ] || [ "$task_status" = "error" ] || [ "$task_status" = "failed" ]; then
        echo "critical"
    elif [ "$heartbeat_status" = "warning" ]; then
        echo "warning"
    else
        echo "healthy"
    fi
}

# Функция получения статуса для вывода
get_status_display() {
    local status="$1"
    
    case "$status" in
        "healthy")
            echo -e "${STATUS_HEALTHY} HEALTHY${NC}"
            ;;
        "warning")
            echo -e "${STATUS_WARNING} WARNING${NC}"
            ;;
        "critical")
            echo -e "${STATUS_CRITICAL} CRITICAL${NC}"
            ;;
        "dead")
            echo -e "${STATUS_DEAD} DEAD${NC}"
            ;;
        *)
            echo -e "${WHITE}UNKNOWN${NC}"
            ;;
    esac
}

# Функция проверки всех агентов
check_all_agents() {
    local target_agent="$1"
    
    section "Health Check Агентов"
    
    if [ ! -d "$WORKTREES_DIR" ]; then
        warn "Директория worktree не найдена: $WORKTREES_DIR"
        return 0
    fi
    
    echo ""
    printf "${WHITE}%-40s %-15s %-15s %-15s${NC}\n" "AGENT" "STATUS" "HEARTBEAT" "TASK"
    printf "${WHITE}%s${NC}\n" "────────────────────────────────────────────────────────────────────────────"
    
    for worktree_dir in "$WORKTREES_DIR"/*/; do
        if [ ! -d "$worktree_dir" ]; then
            continue
        fi
        
        local agent_name=$(basename "$worktree_dir")
        
        # Фильтрация по целевому агенту
        if [ -n "$target_agent" ] && [ "$agent_name" != "$target_agent" ]; then
            continue
        fi
        
        local status=$(get_agent_status "$worktree_dir")
        local status_display=$(get_status_display "$status")
        
        # Получение информации о heartbeat
        local state_file="$worktree_dir/.qwen/gastown-state.json"
        local heartbeat_ago="N/A"
        if [ -f "$state_file" ] && command -v jq &> /dev/null; then
            local last_heartbeat=$(jq -r '.lastHeartbeat // ""' "$state_file" 2>/dev/null)
            if [ -n "$last_heartbeat" ]; then
                local heartbeat_ts=$(date -d "$last_heartbeat" +%s 2>/dev/null || echo "0")
                local current_ts=$(date +%s)
                local diff=$((current_ts - heartbeat_ts))
                
                if [ "$diff" -lt 60 ]; then
                    heartbeat_ago="${diff}s ago"
                elif [ "$diff" -lt 3600 ]; then
                    heartbeat_ago="$((diff / 60))m ago"
                else
                    heartbeat_ago="$((diff / 3600))h ago"
                fi
            fi
        fi
        
        # Получение статуса задачи
        local task_status=$(check_task_status "$worktree_dir")
        
        printf "%-40b %-15b %-15s %-15s\n" "$agent_name" "$status_display" "$heartbeat_ago" "$task_status"
        
        # Подсчет статистики
        case "$status" in
            "healthy") ((HEALTHY_COUNT++)) ;;
            "warning") ((WARNING_COUNT++)) ;;
            "critical") ((CRITICAL_COUNT++)) ;;
            "dead") ((DEAD_COUNT++)) ;;
        esac
    done
    
    return 0
}

# Функция вывода сводки
print_summary() {
    section "Сводка"
    
    local total=$((HEALTHY_COUNT + WARNING_COUNT + CRITICAL_COUNT + DEAD_COUNT))
    
    echo ""
    echo "  Всего агентов:     $total"
    echo "  ${STATUS_HEALTHY} Healthy:        $HEALTHY_COUNT"
    echo "  ${STATUS_WARNING} Warning:        $WARNING_COUNT"
    echo "  ${STATUS_CRITICAL} Critical:       $CRITICAL_COUNT"
    echo "  ${STATUS_DEAD} Dead:           $DEAD_COUNT"
    echo ""
    
    log_action "SUMMARY" "Total: $total, Healthy: $HEALTHY_COUNT, Warning: $WARNING_COUNT, Critical: $CRITICAL_COUNT, Dead: $DEAD_COUNT"
}

# Функция вывода проблем
print_issues() {
    section "Проблемы"
    
    local issues_found=0
    
    for worktree_dir in "$WORKTREES_DIR"/*/; do
        if [ ! -d "$worktree_dir" ]; then
            continue
        fi
        
        local agent_name=$(basename "$worktree_dir")
        local status=$(get_agent_status "$worktree_dir")
        local state_file="$worktree_dir/.qwen/gastown-state.json"
        
        if [ "$status" = "warning" ]; then
            local heartbeat_status=$(check_heartbeat "$state_file")
            if [ "$heartbeat_status" = "warning" ]; then
                warn "$agent_name - Heartbeat delayed"
                ((issues_found++))
            fi
        elif [ "$status" = "critical" ]; then
            local task_status=$(check_task_status "$worktree_dir")
            if [ "$task_status" = "timeout" ]; then
                error "$agent_name - Task timeout"
                ((issues_found++))
            else
                error "$agent_name - Critical status"
                ((issues_found++))
            fi
        elif [ "$status" = "dead" ]; then
            error "$agent_name - Agent unresponsive"
            ((issues_found++))
        fi
    done
    
    if [ "$issues_found" -eq 0 ]; then
        success "Проблем не обнаружено"
    else
        echo ""
        warn "Всего проблем: $issues_found"
    fi
    
    log_action "ISSUES" "Found: $issues_found"
}

# Функция авто-перезапуска агентов
auto_restart_agents() {
    local dry_run="$1"
    
    section "Auto-Restart Агентов"
    
    local restart_count=0
    
    for worktree_dir in "$WORKTREES_DIR"/*/; do
        if [ ! -d "$worktree_dir" ]; then
            continue
        fi
        
        local agent_name=$(basename "$worktree_dir")
        local status=$(get_agent_status "$worktree_dir")
        
        if [ "$status" = "dead" ] || [ "$status" = "critical" ]; then
            if [ "$dry_run" = "true" ]; then
                info "[DRY RUN] Would restart: $agent_name"
                continue
            fi
            
            info "Перезапуск агента: $agent_name"
            
            # Извлечение agent-id из имени worktree
            local agent_id=$(echo "$agent_name" | sed 's/agent-//' | sed 's/-task-.*//')
            
            # Сохранение состояния
            info "Сохранение состояния задачи..."
            local archive_dir="$GASTOWN_DIR/archives/restart-$(date +%Y%m%d-%H%M%S)-$agent_name"
            mkdir -p "$archive_dir"
            if [ -d "$worktree_dir/.qwen/gastown/tasks" ]; then
                cp -r "$worktree_dir/.qwen/gastown/tasks" "$archive_dir/" 2>/dev/null || true
            fi
            success "Состояние сохранено в $archive_dir"
            
            # Остановка процессов (если есть)
            info "Остановка процессов агента..."
            pkill -f "gastown.*$agent_name" 2>/dev/null || true
            success "Процессы остановлены"
            
            # Удаление старого worktree
            info "Удаление старого worktree..."
            if git worktree remove "$worktree_dir" 2>/dev/null; then
                success "Worktree удален"
            else
                warn "Не удалось удалить через git, пробуем принудительно"
                rm -rf "$worktree_dir" && success "Worktree удален принудительно"
            fi
            
            # Пересоздание worktree
            info "Создание нового worktree..."
            local branch="develop"
            if git show-ref --verify --quiet refs/heads/"$branch"; then
                if git worktree add -b "$agent_name" "$worktree_dir" "$branch" 2>/dev/null; then
                    success "Worktree создан"
                else
                    if git worktree add "$worktree_dir" "$branch" 2>/dev/null; then
                        success "Worktree создан"
                    else
                        error "Не удалось создать worktree"
                        continue
                    fi
                fi
            else
                error "Ветка $branch не найдена"
                continue
            fi
            
            # Настройка окружения
            mkdir -p "$worktree_dir/.qwen"
            cat > "$worktree_dir/.qwen/gastown-state.json" << EOF
{
  "agentId": "$agent_id",
  "worktreeName": "$agent_name",
  "worktreePath": "$worktree_dir",
  "initializedAt": "$(date -Iseconds)",
  "restartedAt": "$(date -Iseconds)",
  "status": "active",
  "taskId": null,
  "lastHeartbeat": "$(date -Iseconds)"
}
EOF
            success "Окружение настроено"
            
            success "Агент $agent_name перезапущен"
            ((restart_count++))
            ((RESTARTED_COUNT++))
            
            log_action "RESTART" "Restarted: $agent_name"
        fi
    done
    
    if [ "$restart_count" -eq 0 ]; then
        info "Агенты не требовали перезапуска"
    else
        success "Перезапущено агентов: $restart_count"
    fi
}

# Функция вывода рекомендаций
print_recommendations() {
    section "Рекомендации"
    
    if [ "$DEAD_COUNT" -gt 0 ]; then
        echo "  1. Перезапустите dead агентов: --auto-restart"
    fi
    
    if [ "$CRITICAL_COUNT" -gt 0 ]; then
        echo "  2. Проверьте критические задачи"
    fi
    
    if [ "$WARNING_COUNT" -gt 0 ]; then
        echo "  3. Мониторьте агентов с warning"
    fi
    
    if [ "$HEALTHY_COUNT" -eq $((HEALTHY_COUNT + WARNING_COUNT + CRITICAL_COUNT + DEAD_COUNT)) ] && [ "$HEALTHY_COUNT" -gt 0 ]; then
        echo "  ✅ Все агенты работают нормально"
    fi
    
    echo ""
}

# Функция непрерывного мониторинга
watch_mode() {
    local interval="$1"
    local auto_restart="$2"
    local dry_run="$3"
    
    info "Запуск непрерывного мониторинга (интервал: ${interval}s)"
    
    if [ "$auto_restart" = "true" ]; then
        info "Auto-restart: включен"
    fi
    
    if [ "$dry_run" = "true" ]; then
        info "Dry run: включен"
    fi
    
    info "Нажмите Ctrl+C для остановки"
    echo ""
    
    while true; do
        clear
        
        echo "═══════════════════════════════════════════════════════════"
        echo "  Gastown Witness - Live Health Check"
        echo "  Updated: $(date)"
        echo "  Interval: ${interval}s | Auto-restart: $auto_restart"
        echo "═══════════════════════════════════════════════════════════"
        
        # Сброс счетчиков
        HEALTHY_COUNT=0
        WARNING_COUNT=0
        CRITICAL_COUNT=0
        DEAD_COUNT=0
        
        check_all_agents ""
        print_summary
        print_issues
        
        if [ "$auto_restart" = "true" ]; then
            auto_restart_agents "$dry_run"
        fi
        
        sleep "$interval"
    done
}

# =============================================================================
# Основная логика
# =============================================================================

# Параметры по умолчанию
WATCH_MODE=false
INTERVAL=60
AUTO_RESTART=false
DRY_RUN=false
TARGET_AGENT=""

# Парсинг аргументов
for arg in "$@"; do
    case $arg in
        --help|-h)
            echo "Использование: $0 [options]"
            echo ""
            echo "Мониторинг здоровья агентов, detection зависаний, auto-restart"
            echo ""
            echo "Параметры:"
            echo "  --watch, -w          Непрерывный мониторинг"
            echo "  --interval, -i N     Интервал проверки в секундах (по умолчанию: 60)"
            echo "  --auto-restart       Автоматический перезапуск зависших агентов"
            echo "  --agent NAME         Проверка конкретного агента"
            echo "  --dry-run            Проверка без выполнения действий"
            echo ""
            echo "Примеры:"
            echo "  $0                              # Разовая проверка"
            echo "  $0 --watch --interval 30        # Live мониторинг"
            echo "  $0 --auto-restart               # С авто-перезапуском"
            echo "  $0 --agent agent-name           # Проверка агента"
            exit 0
            ;;
        --watch|-w)
            WATCH_MODE=true
            ;;
        --interval|-i)
            INTERVAL="${2:-60}"
            shift
            ;;
        --auto-restart)
            AUTO_RESTART=true
            ;;
        --agent)
            TARGET_AGENT="${2:-}"
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            ;;
    esac
done

echo ""
echo -e "${CYAN}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║         Gastown Witness - Agent Health Check              ║${NC}"
echo -e "${CYAN}╚═══════════════════════════════════════════════════════════╝${NC}"

# Запуск в режиме watch
if [ "$WATCH_MODE" = true ]; then
    watch_mode "$INTERVAL" "$AUTO_RESTART" "$DRY_RUN"
    exit 0
fi

# Разовая проверка
check_all_agents "$TARGET_AGENT"
print_summary
print_issues

# Auto-restart при необходимости
if [ "$AUTO_RESTART" = true ]; then
    auto_restart_agents "$DRY_RUN"
fi

print_recommendations

log_action "WITNESS_COMPLETE" "Check completed"

# Код возврата
if [ "$DEAD_COUNT" -gt 0 ]; then
    exit 3
elif [ "$CRITICAL_COUNT" -gt 0 ]; then
    exit 2
elif [ "$WARNING_COUNT" -gt 0 ]; then
    exit 1
else
    exit 0
fi
