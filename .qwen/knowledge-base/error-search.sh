#!/bin/bash
#
# error-search.sh - Поиск решений по ошибкам в базе знаний
#
# Назначение: Поиск решений по ошибкам из error-handling-examples.md
#
# Использование:
#   .qwen/knowledge-base/error-search.sh "текст ошибки"     # Поиск по ключевым словам
#   .qwen/knowledge-base/error-search.sh --code "ERR-GIT-001"  # Поиск по коду
#   .qwen/knowledge-base/error-search.sh --context "git"    # Поиск по контексту/категории
#   .qwen/knowledge-base/error-search.sh --list             # Список всех ошибок
#   .qwen/knowledge-base/error-search.sh --help             # Справка
#

set -e

# Пути
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INDEX_FILE="$SCRIPT_DIR/error-index.json"
SOURCE_FILE="$SCRIPT_DIR/../docs/help/error-handling-examples.md"

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Функция вывода справки
show_help() {
    cat << EOF
${CYAN}Error Knowledge Base - Поиск решений по ошибкам${NC}

${YELLOW}Использование:${NC}
  $0 "текст ошибки"              Поиск по ключевым словам в описании ошибки
  $0 --code "ERR-XXX-XXX"        Поиск по коду ошибки
  $0 --context "категория"       Поиск по категории (Git, Quality Gates, Агенты, TDD, MCP, Сборка)
  $0 --list                      Список всех ошибок
  $0 --stats                     Статистика базы знаний
  $0 --help                      Показать эту справку

${YELLOW}Примеры:${NC}
  $0 "Git не инициализирован"
  $0 --code "ERR-GIT-001"
  $0 --context "Git"
  $0 --list

${YELLOW}Категории:${NC}
  - Git          - Ошибки системы контроля версий
  - Quality Gates - Ошибки проверок качества
  - Агенты       - Ошибки связанные с агентами
  - TDD          - Ошибки тестирования
  - MCP          - Ошибки MCP серверов
  - Сборка       - Ошибки компиляции и сборки

EOF
}

# Функция проверки существования индекса
check_index() {
    if [[ ! -f "$INDEX_FILE" ]]; then
        echo -e "${RED}Ошибка: Индекс ошибок не найден: $INDEX_FILE${NC}"
        echo -e "${YELLOW}Запустите auto-learn.sh для создания индекса${NC}"
        exit 1
    fi
}

# Функция поиска по коду ошибки
search_by_code() {
    local code="$1"
    
    echo -e "${CYAN}Поиск по коду: ${YELLOW}$code${NC}"
    echo "=========================================="
    
    # Используем jq для поиска
    local result=$(jq -r --arg code "$code" '
        .errors[] | select(.id == $code) |
        "
${GREEN}ID:${NC} \(.id)
${GREEN}Категория:${NC} \(.category)
${GREEN}Название:${NC} \(.title)
${GREEN}Паттерн:${NC} \(.pattern)
${GREEN}Причина:${NC} \(.cause)
${GREEN}Решение:${NC} \(.solution)
${GREEN}Профилактика:${NC} \(.prevention)
${GREEN}Источник:${NC} \(.file) (раздел \(.section))
${GREEN}Ключевые слова:${NC} \(.keywords | join(", "))
"
    ' "$INDEX_FILE")
    
    if [[ -z "$result" ]]; then
        echo -e "${RED}Ошибка с кодом '$code' не найдена${NC}"
        echo -e "${YELLOW}Используйте --list для просмотра всех доступных кодов${NC}"
        exit 1
    fi
    
    echo -e "$result"
}

# Функция поиска по контексту/категории
search_by_context() {
    local context="$1"
    
    echo -e "${CYAN}Поиск по категории: ${YELLOW}$context${NC}"
    echo "=========================================="
    
    # Поиск по категории (регистронезависимый)
    local results=$(jq -r --arg ctx "$context" '
        .errors[] | select(.category | ascii_downcase | contains($ctx | ascii_downcase)) |
        "
${GREEN}ID:${NC} \(.id)
${GREEN}Категория:${NC} \(.category)
${GREEN}Название:${NC} \(.title)
${GREEN}Паттерн:${NC} \(.pattern)
${GREEN}Причина:${NC} \(.cause)
${GREEN}Решение:${NC} \(.solution)
${GREEN}Профилактика:${NC} \(.prevention)
---"
    ' "$INDEX_FILE")
    
    if [[ -z "$results" ]]; then
        echo -e "${RED}Ошибки в категории '$context' не найдены${NC}"
        echo -e "${YELLOW}Доступные категории: Git, Quality Gates, Агенты, TDD, MCP, Сборка${NC}"
        exit 1
    fi
    
    echo -e "$results"
    
    # Подсчет найденных
    local count=$(jq -r --arg ctx "$context" '[.errors[] | select(.category | ascii_downcase | contains($ctx | ascii_downcase))] | length' "$INDEX_FILE")
    echo ""
    echo -e "${CYAN}Найдено ошибок: ${YELLOW}$count${NC}"
}

# Функция поиска по ключевым словам
search_by_keyword() {
    local keyword="$1"
    
    echo -e "${CYAN}Поиск по ключевым словам: ${YELLOW}$keyword${NC}"
    echo "=========================================="
    
    # Поиск по полям: title, pattern, cause, keywords
    local results=$(jq -r --arg kw "$keyword" '
        .errors[] | select(
            (.title | ascii_downcase | contains($kw | ascii_downcase)) or
            (.pattern | ascii_downcase | contains($kw | ascii_downcase)) or
            (.cause | ascii_downcase | contains($kw | ascii_downcase)) or
            (.keywords | map(ascii_downcase) | any(contains($kw | ascii_downcase)))
        ) |
        "
${GREEN}ID:${NC} \(.id)
${GREEN}Категория:${NC} \(.category)
${GREEN}Название:${NC} \(.title)
${GREEN}Паттерн:${NC} \(.pattern)
${GREEN}Причина:${NC} \(.cause)
${GREEN}Решение:${NC} \(.solution)
${GREEN}Профилактика:${NC} \(.prevention)
${GREEN}Ключевые слова:${NC} \(.keywords | join(", "))
---"
    ' "$INDEX_FILE")
    
    if [[ -z "$results" ]]; then
        echo -e "${RED}Ошибки по запросу '$keyword' не найдены${NC}"
        echo -e "${YELLOW}Попробуйте другие ключевые слова или используйте --list${NC}"
        exit 1
    fi
    
    echo -e "$results"
    
    # Подсчет найденных
    local count=$(jq -r --arg kw "$keyword" '[.errors[] | select(
        (.title | ascii_downcase | contains($kw | ascii_downcase)) or
        (.pattern | ascii_downcase | contains($kw | ascii_downcase)) or
        (.cause | ascii_downcase | contains($kw | ascii_downcase)) or
        (.keywords | map(ascii_downcase) | any(contains($kw | ascii_downcase)))
    )] | length' "$INDEX_FILE")
    echo ""
    echo -e "${CYAN}Найдено ошибок: ${YELLOW}$count${NC}"
}

# Функция списка всех ошибок
list_all() {
    echo -e "${CYAN}Все ошибки в базе знаний:${NC}"
    echo "=========================================="
    
    jq -r '
        .errors[] |
        "\(.id) | \(.category) | \(.title)"
    ' "$INDEX_FILE" | column -t -s '|'
    
    echo ""
    echo -e "${CYAN}Всего ошибок: ${YELLOW}$(jq '.errors | length' "$INDEX_FILE")${NC}"
}

# Функция статистики
show_stats() {
    echo -e "${CYAN}Статистика базы знаний об ошибках:${NC}"
    echo "=========================================="
    
    local total=$(jq '.errors | length' "$INDEX_FILE")
    local version=$(jq -r '.metadata.version' "$INDEX_FILE")
    local created=$(jq -r '.metadata.created' "$INDEX_FILE")
    local source=$(jq -r '.metadata.source' "$INDEX_FILE")
    
    echo -e "${GREEN}Версия:${NC} $version"
    echo -e "${GREEN}Создана:${NC} $created"
    echo -e "${GREEN}Источник:${NC} $source"
    echo -e "${GREEN}Всего ошибок:${NC} $total"
    echo ""
    
    echo -e "${YELLOW}По категориям:${NC}"
    jq -r '
        .errors | group_by(.category) | 
        map({category: .[0].category, count: length}) |
        sort_by(-.count) |
        .[] |
        "  \(.category): \(.count)"
    ' "$INDEX_FILE"
    
    echo ""
    echo -e "${YELLOW}Категории:${NC}"
    jq -r '.categories[]' "$INDEX_FILE" | while read cat; do
        echo "  - $cat"
    done
}

# Основная логика
main() {
    # Проверка аргументов
    if [[ $# -eq 0 ]]; then
        show_help
        exit 0
    fi
    
    check_index
    
    case "$1" in
        --code)
            if [[ -z "$2" ]]; then
                echo -e "${RED}Ошибка: Укажите код ошибки${NC}"
                echo -e "${YELLOW}Пример: $0 --code ERR-GIT-001${NC}"
                exit 1
            fi
            search_by_code "$2"
            ;;
        --context)
            if [[ -z "$2" ]]; then
                echo -e "${RED}Ошибка: Укажите категорию${NC}"
                echo -e "${YELLOW}Пример: $0 --context Git${NC}"
                exit 1
            fi
            search_by_context "$2"
            ;;
        --list)
            list_all
            ;;
        --stats)
            show_stats
            ;;
        --help|-h)
            show_help
            ;;
        *)
            # Поиск по ключевым словам
            search_by_keyword "$1"
            ;;
    esac
}

# Запуск
main "$@"
