#!/bin/bash

# =============================================================================
# MCP Health Check
# =============================================================================
# Проверяет состояние всех активных MCP серверов
# 
# Использование:
#   .qwen/scripts/mcp/health-check.sh
# =============================================================================

set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Пути
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
QWEN_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"
MCP_ACTIVE_FILE="$QWEN_DIR/mcp.json"

# Таймаут для проверок (в секундах)
TIMEOUT=5

# Счетчики
TOTAL_SERVERS=0
HEALTHY_SERVERS=0
UNHEALTHY_SERVERS=0

# Функция для вывода сообщений
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_header() {
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}$1${NC}"
    echo -e "${CYAN}========================================${NC}"
}

# Функция для проверки доступности команды
check_command() {
    local cmd="$1"
    if command -v "$cmd" &> /dev/null; then
        return 0
    fi
    return 1
}

# Функция для извлечения серверов из JSON
get_servers() {
    local config_file="$1"
    
    if command -v jq &> /dev/null; then
        jq -r '.mcpServers | keys[]' "$config_file" 2>/dev/null
    elif command -v python3 &> /dev/null; then
        python3 -c "
import json
with open('$config_file') as f:
    data = json.load(f)
    for key in data.get('mcpServers', {}).keys():
        print(key)
" 2>/dev/null
    else
        log_error "Не найдено инструментов для парсинга JSON (jq или python3)"
        return 1
    fi
}

# Функция для получения информации о сервере
get_server_info() {
    local config_file="$1"
    local server_name="$2"
    
    if command -v jq &> /dev/null; then
        jq -r ".mcpServers[\"$server_name\"]" "$config_file" 2>/dev/null
    elif command -v python3 &> /dev/null; then
        python3 -c "
import json
with open('$config_file') as f:
    data = json.load(f)
    server = data.get('mcpServers', {}).get('$server_name', {})
    print(json.dumps(server, indent=2))
" 2>/dev/null
    fi
}

# Функция для проверки сервера
check_server() {
    local server_name="$1"
    local server_info="$2"
    
    # Извлечение команды
    local command=""
    if command -v jq &> /dev/null; then
        command=$(echo "$server_info" | jq -r '.command // empty' 2>/dev/null)
    elif command -v python3 &> /dev/null; then
        command=$(python3 -c "
import json
info = json.loads('''$server_info''')
print(info.get('command', ''))
" 2>/dev/null)
    fi
    
    if [[ -z "$command" ]]; then
        log_warning "$server_name: Не найдена команда"
        return 1
    fi
    
    # Проверка доступности команды
    if check_command "$command"; then
        log_success "$server_name: Команда '$command' доступна"
        return 0
    else
        log_error "$server_name: Команда '$command' не найдена"
        return 1
    fi
}

# Функция для проверки переменных окружения
check_env_vars() {
    local server_name="$1"
    local server_info="$2"
    
    # Извлечение переменных окружения
    local env_vars=""
    if command -v jq &> /dev/null; then
        env_vars=$(echo "$server_info" | jq -r '.env // {} | keys[]' 2>/dev/null)
    elif command -v python3 &> /dev/null; then
        env_vars=$(python3 -c "
import json
info = json.loads('''$server_info''')
for key in info.get('env', {}).keys():
    print(key)
" 2>/dev/null)
    fi
    
    if [[ -z "$env_vars" ]]; then
        return 0  # Нет переменных окружения для проверки
    fi
    
    local all_set=true
    while IFS= read -r var; do
        if [[ -z "${!var}" ]] && [[ "$var" != *'\${'* ]]; then
            # Проверяем, не является ли это шаблоном ${VAR}
            if [[ "$var" == *'$'* ]] || [[ "$var" == *'{'* ]]; then
                continue
            fi
            log_warning "$server_name: Переменная окружения '$var' не установлена"
            all_set=false
        fi
    done <<< "$env_vars"
    
    if $all_set; then
        return 0
    fi
    return 1
}

# Основная функция проверки
run_health_check() {
    log_header "MCP Health Check"
    echo ""
    
    # Проверка существования файла конфигурации
    if [[ ! -f "$MCP_ACTIVE_FILE" ]]; then
        log_error "Файл конфигурации не найден: $MCP_ACTIVE_FILE"
        exit 1
    fi
    
    log_info "Конфигурация: $MCP_ACTIVE_FILE"
    echo ""
    
    # Получение списка серверов
    local servers
    servers=$(get_servers "$MCP_ACTIVE_FILE")
    
    if [[ -z "$servers" ]]; then
        log_error "Не удалось получить список серверов"
        exit 1
    fi
    
    log_header "Проверка серверов"
    echo ""
    
    # Проверка каждого сервера
    while IFS= read -r server_name; do
        if [[ -z "$server_name" ]]; then
            continue
        fi
        
        ((TOTAL_SERVERS++))
        
        local server_info
        server_info=$(get_server_info "$MCP_ACTIVE_FILE" "$server_name")
        
        echo -e "${CYAN}Сервер: $server_name${NC}"
        
        # Проверка команды
        if check_server "$server_name" "$server_info"; then
            # Проверка переменных окружения
            if check_env_vars "$server_name" "$server_info"; then
                ((HEALTHY_SERVERS++))
            else
                ((UNHEALTHY_SERVERS++))
            fi
        else
            ((UNHEALTHY_SERVERS++))
        fi
        
        echo ""
    done <<< "$servers"
    
    # Вывод итогов
    log_header "Итоги"
    echo ""
    echo "Всего серверов:    $TOTAL_SERVERS"
    echo -e "Исправны:          ${GREEN}$HEALTHY_SERVERS${NC}"
    echo -e "Проблемы:          ${RED}$UNHEALTHY_SERVERS${NC}"
    echo ""
    
    if [[ $UNHEALTHY_SERVERS -gt 0 ]]; then
        log_warning "Некоторые серверы имеют проблемы"
        exit 1
    else
        log_success "Все серверы исправны"
        exit 0
    fi
}

# Запуск проверки
run_health_check
