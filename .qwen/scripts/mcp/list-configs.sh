#!/bin/bash

# =============================================================================
# MCP Configurations List
# =============================================================================
# Выводит список доступных конфигураций MCP серверов
# 
# Использование:
#   .qwen/scripts/mcp/list-configs.sh
# =============================================================================

set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Пути
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
QWEN_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"
MCP_CONFIG_DIR="$QWEN_DIR"
MCP_ACTIVE_FILE="$QWEN_DIR/mcp.json"

# Функция для вывода сообщений
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_header() {
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}$1${NC}"
    echo -e "${CYAN}========================================${NC}"
}

# Функция для получения метаданных из JSON
get_metadata() {
    local file="$1"
    local field="$2"
    
    if command -v jq &> /dev/null; then
        jq -r "._metadata.${field} // \"N/A\"" "$file" 2>/dev/null
    elif command -v python3 &> /dev/null; then
        python3 -c "
import json
with open('$file') as f:
    data = json.load(f)
    print(data.get('_metadata', {}).get('$field', 'N/A'))
" 2>/dev/null
    else
        echo "N/A"
    fi
}

# Функция для получения количества серверов
get_servers_count() {
    local file="$1"
    
    if command -v jq &> /dev/null; then
        jq -r '.mcpServers | length' "$file" 2>/dev/null
    elif command -v python3 &> /dev/null; then
        python3 -c "
import json
with open('$file') as f:
    data = json.load(f)
    print(len(data.get('mcpServers', {})))
" 2>/dev/null
    else
        echo "N/A"
    fi
}

# Функция для получения списка серверов
get_servers_list() {
    local file="$1"
    
    if command -v jq &> /dev/null; then
        jq -r '.mcpServers | keys | join(", ")' "$file" 2>/dev/null
    elif command -v python3 &> /dev/null; then
        python3 -c "
import json
with open('$file') as f:
    data = json.load(f)
    print(', '.join(data.get('mcpServers', {}).keys()))
" 2>/dev/null
    else
        echo "N/A"
    fi
}

# Функция для получения категорий
get_categories() {
    local file="$1"
    
    if command -v jq &> /dev/null; then
        jq -r '._metadata.categories // [] | join(", ")' "$file" 2>/dev/null
    elif command -v python3 &> /dev/null; then
        python3 -c "
import json
with open('$file') as f:
    data = json.load(f)
    cats = data.get('_metadata', {}).get('categories', [])
    print(', '.join(cats) if cats else 'N/A')
" 2>/dev/null
    else
        echo "N/A"
    fi
}

# Функция для проверки, является ли файл активной конфигурацией
is_active_config() {
    local file="$1"
    local config_name="$2"
    
    if [[ ! -f "$MCP_ACTIVE_FILE" ]]; then
        return 1
    fi
    
    # Сравниваем количество серверов и имена
    local active_count config_count
    active_count=$(get_servers_count "$MCP_ACTIVE_FILE")
    config_count=$(get_servers_count "$file")
    
    if [[ "$active_count" != "$config_count" ]]; then
        return 1
    fi
    
    # Дополнительная проверка по имени в metadata
    local active_name
    active_name=$(get_metadata "$MCP_ACTIVE_FILE" "name")
    
    if [[ "$active_name" == "$config_name" ]]; then
        return 0
    fi
    
    return 1
}

# Основная функция
list_configs() {
    log_header "MCP Configurations"
    echo ""
    
    # Поиск файлов конфигурации
    local config_files
    config_files=$(find "$MCP_CONFIG_DIR" -maxdepth 1 -name "mcp.*.json" -type f 2>/dev/null | sort)
    
    if [[ -z "$config_files" ]]; then
        log_info "Конфигурации не найдены в $MCP_CONFIG_DIR"
        exit 0
    fi
    
    log_info "Директория: $MCP_CONFIG_DIR"
    echo ""
    
    # Вывод активной конфигурации
    if [[ -f "$MCP_ACTIVE_FILE" ]]; then
        local active_name
        active_name=$(get_metadata "$MCP_ACTIVE_FILE" "name")
        if [[ "$active_name" == "N/A" ]]; then
            active_name="mcp.json (custom)"
        fi
        echo -e "Текущая активная конфигурация: ${GREEN}$active_name${NC}"
    else
        echo -e "Текущая активная конфигурация: ${YELLOW}не установлена${NC}"
    fi
    echo ""
    
    log_header "Доступные конфигурации"
    echo ""
    
    # Таблица конфигураций
    printf "%-20s %-10s %-12s %-30s\n" "НАЗВАНИЕ" "СЕРВЕРЫ" "КАТЕГОРИИ" "ОПИСАНИЕ"
    printf "%-20s %-10s %-12s %-30s\n" "--------" "-------" "---------" "--------"
    
    while IFS= read -r config_file; do
        if [[ -z "$config_file" ]]; then
            continue
        fi
        
        # Извлечение имени из пути файла
        local filename basename config_name
        filename=$(basename "$config_file")
        basename="${filename#mcp.}"
        config_name="${basename%.json}"
        
        # Получение метаданных
        local description servers_count categories
        description=$(get_metadata "$config_file" "description")
        servers_count=$(get_servers_count "$config_file")
        categories=$(get_categories "$config_file")
        
        # Обрезка длинных строк
        if [[ ${#description} -gt 28 ]]; then
            description="${description:0:25}..."
        fi
        if [[ ${#categories} -gt 10 ]]; then
            categories="${categories:0:7}..."
        fi
        
        # Индикатор активной конфигурации
        local indicator=""
        if is_active_config "$config_file" "$config_name"; then
            indicator="*"
        fi
        
        printf "%-20s %-10s %-12s %-30s\n" "${indicator}${config_name}" "$servers_count" "$categories" "$description"
        
    done <<< "$config_files"
    
    echo ""
    echo "* - активная конфигурация"
    echo ""
    
    # Детальная информация о каждой конфигурации
    log_header "Детальная информация"
    echo ""
    
    while IFS= read -r config_file; do
        if [[ -z "$config_file" ]]; then
            continue
        fi
        
        local filename config_name
        filename=$(basename "$config_file")
        config_name="${filename#mcp.}"
        config_name="${config_name%.json}"
        
        local description version servers_count categories servers_list
        description=$(get_metadata "$config_file" "description")
        version=$(get_metadata "$config_file" "version")
        servers_count=$(get_servers_count "$config_file")
        categories=$(get_categories "$config_file")
        servers_list=$(get_servers_list "$config_file")
        
        echo -e "${MAGENTA}$config_name${NC}"
        echo "  Описание:   $description"
        echo "  Версия:     $version"
        echo "  Серверы:    $servers_count"
        echo "  Категории:  $categories"
        echo "  Серверы:    $servers_list"
        
        if is_active_config "$config_file" "$config_name"; then
            echo -e "  Статус:     ${GREEN}АКТИВНА${NC}"
        else
            echo "  Статус:     Неактивна"
        fi
        echo ""
        
    done <<< "$config_files"
    
    # Инструкция по переключению
    log_header "Использование"
    echo ""
    echo "Для переключения конфигурации используйте:"
    echo ""
    echo "  .qwen/scripts/mcp/switch-config.sh <config-name>"
    echo ""
    echo "Примеры:"
    echo "  .qwen/scripts/mcp/switch-config.sh base"
    echo "  .qwen/scripts/mcp/switch-config.sh database"
    echo "  .qwen/scripts/mcp/switch-config.sh full"
    echo ""
}

# Запуск
list_configs
