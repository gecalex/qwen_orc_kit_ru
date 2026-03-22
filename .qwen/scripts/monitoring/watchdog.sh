#!/bin/bash
#
# Watchdog Script - Мониторинг зависших задач
# Назначение: Мониторинг длительности задач, уведомление о превышении timeout,
#             автоматическая остановка, сохранение логов
#
# Использование:
#   ./watchdog.sh [OPTIONS]
#
# Опции:
#   --check           Проверить текущие задачи
#   --monitor         Запустить непрерывный мониторинг
#   --kill <task-id>  Принудительно остановить задачу
#   --status          Показать статус всех задач
#   --help            Показать справку
#

set -euo pipefail

# Конфигурация
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
WATCHDOG_LOG="${PROJECT_ROOT}/.qwen/logs/watchdog.log"
STATE_DIR="${PROJECT_ROOT}/.qwen/state"
TASKS_DIR="${PROJECT_ROOT}/.qwen/specify/specs"
PID_DIR="${PROJECT_ROOT}/.qwen/pids"

# Timeout настройки (в секундах)
DEFAULT_TIMEOUT=300          # 5 минут по умолчанию
PLANNING_TIMEOUT=300         # 5 минут
DEVELOPMENT_TIMEOUT=600      # 10 минут
TESTING_TIMEOUT=300          # 5 минут
DOCUMENTATION_TIMEOUT=180    # 3 минуты
ANALYSIS_TIMEOUT=300         # 5 минут

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Логирование
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date -Iseconds)
    echo "[$timestamp] [$level] $message" >> "$WATCHDOG_LOG"
    
    case "$level" in
        ERROR)   echo -e "${RED}[$level]${NC} $message" ;;
        WARN)    echo -e "${YELLOW}[$level]${NC} $message" ;;
        INFO)    echo -e "${GREEN}[$level]${NC} $message" ;;
        DEBUG)   echo -e "${BLUE}[$level]${NC} $message" ;;
        *)       echo "[$level] $message" ;;
    esac
}

# Инициализация директорий
init_dirs() {
    mkdir -p "$STATE_DIR" "$PID_DIR" "$(dirname "$WATCHDOG_LOG")"
    touch "$WATCHDOG_LOG"
}

# Получить список активных задач
get_active_tasks() {
    local tasks=()

    # Поиск PID файлов
    if [ -d "$PID_DIR" ]; then
        shopt -s nullglob
        for pid_file in "$PID_DIR"/*.pid; do
            if [ -f "$pid_file" ]; then
                local task_id=$(basename "$pid_file" .pid)
                local pid=$(cat "$pid_file")

                # Проверка, жив ли процесс
                if kill -0 "$pid" 2>/dev/null; then
                    tasks+=("$task_id:$pid")
                else
                    # Процесс мертв, удалить PID файл
                    rm -f "$pid_file"
                fi
            fi
        done
        shopt -u nullglob
    fi
    
    printf '%s\n' "${tasks[@]}"
}

# Получить время начала задачи
get_task_start_time() {
    local task_id="$1"
    local state_file="${STATE_DIR}/${task_id}-state.json"
    
    if [ -f "$state_file" ]; then
        # Извлечь startTime из JSON
        grep -o '"startTime"[[:space:]]*:[[:space:]]*"[^"]*"' "$state_file" 2>/dev/null | \
            head -1 | \
            sed 's/.*"\([^"]*\)"$/\1/' || echo ""
    else
        # Попробовать найти по PID файлу
        local pid_file="${PID_DIR}/${task_id}.pid"
        if [ -f "$pid_file" ]; then
            stat -c %Y "$pid_file" 2>/dev/null || echo ""
        fi
    fi
}

# Получить тип задачи
get_task_type() {
    local task_id="$1"
    
    case "$task_id" in
        *planning*|*plan*) echo "planning" ;;
        *dev*|*develop*|*code*) echo "development" ;;
        *test*|*testing*) echo "testing" ;;
        *doc*|*document*) echo "documentation" ;;
        *analysis*|*analyze*) echo "analysis" ;;
        *) echo "default" ;;
    esac
}

# Получить timeout для типа задачи
get_timeout_for_type() {
    local task_type="$1"
    
    case "$task_type" in
        planning)     echo "$PLANNING_TIMEOUT" ;;
        development)  echo "$DEVELOPMENT_TIMEOUT" ;;
        testing)      echo "$TESTING_TIMEOUT" ;;
        documentation) echo "$DOCUMENTATION_TIMEOUT" ;;
        analysis)     echo "$ANALYSIS_TIMEOUT" ;;
        *)            echo "$DEFAULT_TIMEOUT" ;;
    esac
}

# Форматирование времени
format_duration() {
    local seconds=$1
    
    if [ $seconds -lt 60 ]; then
        echo "${seconds}с"
    elif [ $seconds -lt 3600 ]; then
        echo "$((seconds / 60))м $((seconds % 60))с"
    else
        echo "$((seconds / 3600))ч $((seconds % 3600 / 60))м"
    fi
}

# Проверка одной задачи на timeout
check_task_timeout() {
    local task_id="$1"
    local pid="$2"
    
    local start_time=$(get_task_start_time "$task_id")
    local current_time=$(date +%s)
    local elapsed=0
    
    if [ -n "$start_time" ]; then
        # Если start_time в формате epoch
        if [[ "$start_time" =~ ^[0-9]+$ ]]; then
            elapsed=$((current_time - start_time))
        else
            # Если start_time в ISO формате
            local start_epoch=$(date -d "$start_time" +%s 2>/dev/null || echo "$current_time")
            elapsed=$((current_time - start_epoch))
        fi
    fi
    
    local task_type=$(get_task_type "$task_id")
    local timeout=$(get_timeout_for_type "$task_type")
    local remaining=$((timeout - elapsed))
    
    # Вывод статуса
    local status_color="$GREEN"
    local status_text="OK"
    
    if [ $elapsed -gt $timeout ]; then
        status_color="$RED"
        status_text="TIMEOUT"
    elif [ $remaining -lt 60 ]; then
        status_color="$YELLOW"
        status_text="WARNING"
    fi
    
    printf "%-30s | PID: %-6s | Тип: %-15s | Время: %-10s | Лимит: %-10s | Статус: ${status_color}%-10s${NC}\n" \
        "$task_id" "$pid" "$task_type" "$(format_duration $elapsed)" "$(format_duration $timeout)" "$status_text"
    
    # Возврат кода статуса
    if [ $elapsed -gt $timeout ]; then
        return 1  # Timeout
    elif [ $remaining -lt 60 ]; then
        return 2  # Warning
    else
        return 0  # OK
    fi
}

# Команда: Проверить текущие задачи
cmd_check() {
    log INFO "Проверка активных задач..."
    echo ""
    echo "════════════════════════════════════════════════════════════════════════════════"
    echo "                           WATCHDOG - ПРОВЕРКА ЗАДААЧ"
    echo "════════════════════════════════════════════════════════════════════════════════"
    printf "%-30s | %-8s | %-15s | %-10s | %-10s | %-10s\n" \
        "Задача" "PID" "Тип" "Время" "Лимит" "Статус"
    echo "────────────────────────────────────────────────────────────────────────────────"
    
    local timeout_count=0
    local warning_count=0
    local ok_count=0
    
    while IFS= read -r task_entry; do
        if [ -n "$task_entry" ]; then
            local task_id="${task_entry%%:*}"
            local pid="${task_entry##*:}"
            
            if check_task_timeout "$task_id" "$pid"; then
                ((ok_count++))
            else
                local exit_code=$?
                if [ $exit_code -eq 1 ]; then
                    ((timeout_count++))
                elif [ $exit_code -eq 2 ]; then
                    ((warning_count++))
                fi
            fi
        fi
    done < <(get_active_tasks)
    
    echo "────────────────────────────────────────────────────────────────────────────────"
    echo -e "Итого: ${GREEN}OK: $ok_count${NC} | ${YELLOW}Warning: $warning_count${NC} | ${RED}Timeout: $timeout_count${NC}"
    echo "════════════════════════════════════════════════════════════════════════════════"
    echo ""
    
    if [ $timeout_count -gt 0 ]; then
        log WARN "Обнаружено задач с timeout: $timeout_count"
        return 1
    fi
    
    return 0
}

# Команда: Непрерывный мониторинг
cmd_monitor() {
    local interval="${1:-60}"  # Интервал проверки в секундах (по умолчанию 60)
    
    log INFO "Запуск непрерывного мониторинга (интервал: ${interval}с)..."
    echo ""
    echo "════════════════════════════════════════════════════════════════════════════════"
    echo "                    WATCHDOG - НЕПРЕРЫВНЫЙ МОНИТОРИНГ"
    echo "════════════════════════════════════════════════════════════════════════════════"
    echo "Интервал проверки: ${interval}с"
    echo "Для остановки нажмите Ctrl+C"
    echo "────────────────────────────────────────────────────────────────────────────────"
    echo ""
    
    trap 'echo ""; log INFO "Мониторинг остановлен пользователем"; exit 0' INT TERM
    
    while true; do
        clear
        echo "Последняя проверка: $(date -Iseconds)"
        echo ""
        cmd_check
        
        local timeout_tasks=$(get_active_tasks | while IFS= read -r task_entry; do
            if [ -n "$task_entry" ]; then
                local task_id="${task_entry%%:*}"
                local pid="${task_entry##*:}"
                check_task_timeout "$task_id" "$pid" 2>/dev/null || echo "$task_id"
            fi
        done)
        
        if [ -n "$timeout_tasks" ]; then
            log WARN "Обнаружены задачи с timeout: $timeout_tasks"
            
            # Автоматическая остановка зависших задач
            for task_id in $timeout_tasks; do
                log WARN "Автоматическая остановка задачи: $task_id"
                cmd_kill "$task_id"
            done
        fi
        
        sleep "$interval"
    done
}

# Команда: Принудительная остановка задачи
cmd_kill() {
    local task_id="$1"
    
    if [ -z "$task_id" ]; then
        log ERROR "Не указан task-id"
        echo "Использование: $0 --kill <task-id>"
        return 1
    fi
    
    local pid_file="${PID_DIR}/${task_id}.pid"
    
    if [ ! -f "$pid_file" ]; then
        log WARN "PID файл не найден для задачи: $task_id"
        return 1
    fi
    
    local pid=$(cat "$pid_file")
    
    if ! kill -0 "$pid" 2>/dev/null; then
        log WARN "Процесс $pid уже не существует"
        rm -f "$pid_file"
        return 1
    fi
    
    log WARN "Остановка задачи $task_id (PID: $pid)..."
    
    # 1. Попытка graceful shutdown
    log INFO "Попытка корректной остановки..."
    kill -TERM "$pid" 2>/dev/null || true
    
    # Ожидание завершения (до 10 секунд)
    local wait_count=0
    while kill -0 "$pid" 2>/dev/null && [ $wait_count -lt 10 ]; do
        sleep 1
        ((wait_count++))
    done
    
    # 2. Если не завершился - принудительная остановка
    if kill -0 "$pid" 2>/dev/null; then
        log WARN "Graceful shutdown не удался, принудительная остановка..."
        kill -KILL "$pid" 2>/dev/null || true
    fi
    
    # 3. Сохранение логов
    log INFO "Сохранение логов задачи..."
    save_task_logs "$task_id"
    
    # 4. Очистка PID файла
    rm -f "$pid_file"
    
    log INFO "Задача $task_id остановлена"
    return 0
}

# Сохранение логов задачи
save_task_logs() {
    local task_id="$1"
    local archive_dir="${PROJECT_ROOT}/.qwen/logs/archives"
    local timestamp=$(date +%Y%m%d_%H%M%S)
    
    mkdir -p "$archive_dir"
    
    # Копирование логов
    if [ -f "${PROJECT_ROOT}/.qwen/logs/${task_id}.log" ]; then
        cp "${PROJECT_ROOT}/.qwen/logs/${task_id}.log" \
           "${archive_dir}/${task_id}_${timestamp}.log"
        log INFO "Лог сохранен: ${archive_dir}/${task_id}_${timestamp}.log"
    fi
    
    # Копирование state файла
    if [ -f "${STATE_DIR}/${task_id}-state.json" ]; then
        cp "${STATE_DIR}/${task_id}-state.json" \
           "${archive_dir}/${task_id}_${timestamp}-state.json"
        log INFO "State сохранен: ${archive_dir}/${task_id}_${timestamp}-state.json"
    fi
}

# Команда: Показать статус всех задач
cmd_status() {
    log INFO "Статус всех задач..."
    echo ""
    echo "════════════════════════════════════════════════════════════════════════════════"
    echo "                           WATCHDOG - СТАТУС ЗАДААЧ"
    echo "════════════════════════════════════════════════════════════════════════════════"
    echo ""
    
    # Активные задачи
    echo "Активные задачи:"
    echo "────────────────────────────────────────────────────────────────────────────────"
    local active_count=0
    while IFS= read -r task_entry; do
        if [ -n "$task_entry" ]; then
            local task_id="${task_entry%%:*}"
            local pid="${task_entry##*:}"
            echo "  - $task_id (PID: $pid)"
            ((active_count++))
        fi
    done < <(get_active_tasks)
    
    if [ $active_count -eq 0 ]; then
        echo "  Нет активных задач"
    fi
    
    echo ""
    echo "Последние остановленные задачи:"
    echo "────────────────────────────────────────────────────────────────────────────────"
    
    # Последние логи остановленных задач
    local archive_dir="${PROJECT_ROOT}/.qwen/logs/archives"
    if [ -d "$archive_dir" ]; then
        ls -lt "$archive_dir"/*.log 2>/dev/null | head -5 | while read -r line; do
            echo "  - $(basename "$line" .log)"
        done
    else
        echo "  Нет архивных логов"
    fi
    
    echo ""
    echo "════════════════════════════════════════════════════════════════════════════════"
    echo "Всего активных: $active_count"
    echo ""
}

# Показать справку
cmd_help() {
    cat << EOF
Watchdog Script - Мониторинг зависших задач

Использование:
  $0 [OPTIONS]

Опции:
  --check           Проверить текущие задачи на timeout
  --monitor [INT]   Запустить непрерывный мониторинг (INT - интервал в секундах)
  --kill <task-id>  Принудительно остановить задачу
  --status          Показать статус всех задач
  --help            Показать эту справку

Примеры:
  $0 --check                          # Проверить все активные задачи
  $0 --monitor 30                     # Мониторинг каждые 30 секунд
  $0 --kill dev-task-123              # Остановить задачу dev-task-123
  $0 --status                         # Показать статус

Настройки timeout:
  Planning:      5 минут (300с)
  Development:   10 минут (600с)
  Testing:       5 минут (300с)
  Documentation: 3 минуты (180с)
  Analysis:      5 минут (300с)

Лог файл: $WATCHDOG_LOG
EOF
}

# Основная функция
main() {
    init_dirs
    
    if [ $# -eq 0 ]; then
        cmd_help
        exit 1
    fi
    
    case "$1" in
        --check)
            cmd_check
            ;;
        --monitor)
            cmd_monitor "${2:-60}"
            ;;
        --kill)
            cmd_kill "$2"
            ;;
        --status)
            cmd_status
            ;;
        --help|-h)
            cmd_help
            ;;
        *)
            log ERROR "Неизвестная опция: $1"
            cmd_help
            exit 1
            ;;
    esac
}

main "$@"
