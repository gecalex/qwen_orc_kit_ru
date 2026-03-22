#!/bin/bash

# =============================================================================
# MCP Configuration Switcher
# =============================================================================
# Переключает конфигурацию MCP серверов между различными профилями
# 
# Использование:
#   .qwen/scripts/mcp/switch-config.sh <config-name>
#
# Доступные конфигурации:
#   base         - Базовая конфигурация (context7, searxng, chrome-devtools)
#   database     - Конфигурация для работы с базами данных
#   testing      - Конфигурация для тестирования
#   infrastructure - Конфигурация для инфраструктуры
#   full         - Полная конфигурация всех серверов
# =============================================================================

set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Функция для проверки существования файла конфигурации
check_config_exists() {
    local config_name="$1"
    local config_file="$MCP_CONFIG_DIR/mcp.${config_name}.json"
    
    if [[ ! -f "$config_file" ]]; then
        log_error "Конфигурация '$config_name' не найдена: $config_file"
        return 1
    fi
    return 0
}

# Функция для валидации JSON
validate_json() {
    local file="$1"
    
    if command -v jq &> /dev/null; then
        if ! jq empty "$file" 2>/dev/null; then
            log_error "Невалидный JSON в файле: $file"
            return 1
        fi
    elif command -v python3 &> /dev/null; then
        if ! python3 -c "import json; json.load(open('$file'))" 2>/dev/null; then
            log_error "Невалидный JSON в файле: $file"
            return 1
        fi
    else
        log_warning "Не найдено инструментов для валидации JSON (jq или python3)"
    fi
    return 0
}

# Функция для создания резервной копии
create_backup() {
    if [[ -f "$MCP_ACTIVE_FILE" ]]; then
        local backup_file="${MCP_ACTIVE_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
        cp "$MCP_ACTIVE_FILE" "$backup_file"
        log_info "Создана резервная копия: $backup_file"
    fi
}

# Функция для переключения конфигурации
switch_config() {
    local config_name="$1"
    local source_file="$MCP_CONFIG_DIR/mcp.${config_name}.json"
    
    log_info "Переключение на конфигурацию: $config_name"
    
    # Проверка существования файла
    if ! check_config_exists "$config_name"; then
        return 1
    fi
    
    # Валидация JSON
    log_info "Валидация JSON..."
    if ! validate_json "$source_file"; then
        log_error "Конфигурация содержит ошибки JSON"
        return 1
    fi
    
    # Создание резервной копии
    create_backup
    
    # Копирование конфигурации
    cp "$source_file" "$MCP_ACTIVE_FILE"
    
    # Удаление _metadata из активной конфигурации (опционально)
    # Если хотите сохранить metadata, закомментируйте следующие строки
    if command -v jq &> /dev/null; then
        jq 'del(._metadata)' "$MCP_ACTIVE_FILE" > "${MCP_ACTIVE_FILE}.tmp" && \
        mv "${MCP_ACTIVE_FILE}.tmp" "$MCP_ACTIVE_FILE"
    fi
    
    log_success "Конфигурация успешно переключена на: $config_name"
    log_info "Активный файл: $MCP_ACTIVE_FILE"
    
    # Информация о перезагрузке
    echo ""
    log_warning "Для применения изменений необходимо перезапустить Qwen Code"
    echo ""
    echo "  1. Закройте Qwen Code"
    echo "  2. Запустите заново"
    echo ""
    echo "  Или используйте команду перезагрузки MCP (если доступна):"
    echo "  /mcp-reload"
    echo ""
    
    return 0
}

# Функция для вывода справки
show_help() {
    echo "MCP Configuration Switcher"
    echo ""
    echo "Использование:"
    echo "  $0 <config-name>"
    echo ""
    echo "Доступные конфигурации:"
    echo "  base           - Базовая конфигурация (context7, searxng, chrome-devtools)"
    echo "  database       - Конфигурация для работы с базами данных"
    echo "  testing        - Конфигурация для тестирования"
    echo "  infrastructure - Конфигурация для инфраструктуры"
    echo "  full           - Полная конфигурация всех серверов"
    echo ""
    echo "Примеры:"
    echo "  $0 base"
    echo "  $0 database"
    echo "  $0 full"
    echo ""
}

# Основная логика
main() {
    if [[ $# -eq 0 ]]; then
        show_help
        exit 1
    fi
    
    local config_name="$1"
    
    # Проверка специальных команд
    if [[ "$config_name" == "-h" ]] || [[ "$config_name" == "--help" ]]; then
        show_help
        exit 0
    fi
    
    # Переключение конфигурации
    switch_config "$config_name"
}

main "$@"
