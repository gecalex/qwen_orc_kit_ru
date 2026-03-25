#!/bin/bash
#
# auto-learn.sh - Автоматическое обучение на новых ошибках
#
# Назначение: Парсинг логов ошибок, извлечение паттернов, добавление в базу знаний
#
# Использование:
#   .qwen/knowledge-base/auto-learn.sh                    # Автообучение из логов
#   .qwen/knowledge-base/auto-learn.sh --rebuild          # Пересоздать индекс
#   .qwen/knowledge-base/auto-learn.sh --add <file>       # Добавить ошибки из файла
#   .qwen/knowledge-base/auto-learn.sh --scan <dir>       # Сканировать директорию
#   .qwen/knowledge-base/auto-learn.sh --help             # Справка
#

set -e

# Пути
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INDEX_FILE="$SCRIPT_DIR/error-index.json"
SOURCE_FILE="$SCRIPT_DIR/../docs/help/error-handling-examples.md"
LOGS_DIR="$SCRIPT_DIR/../logs"
LEARNED_DIR="$SCRIPT_DIR/learned"

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
${CYAN}Auto-Learn - Автоматическое обучение на ошибках${NC}

${YELLOW}Использование:${NC}
  $0                              Автообучение из логов и источников
  $0 --rebuild                    Пересоздать индекс из источника
  $0 --add <файл>                 Добавить ошибки из файла логов
  $0 --scan <директория>          Сканировать директорию на ошибки
  $0 --validate                   Проверить целостность индекса
  $0 --stats                      Статистика обучения
  $0 --help                       Показать эту справку

${YELLOW}Источники обучения:${NC}
  - error-handling-examples.md    Основной источник примеров
  - .qwen/logs/                   Логи выполнения
  - .qwen/reports/                Отчеты об ошибках
  - state/                        Файлы состояния

${YELLOW}Категории ошибок:${NC}
  - Git          - Ошибки системы контроля версий
  - Quality Gates - Ошибки проверок качества
  - Агенты       - Ошибки связанные с агентами
  - TDD          - Ошибки тестирования
  - MCP          - Ошибки MCP серверов
  - Сборка       - Ошибки компиляции и сборки

EOF
}

# Функция проверки зависимостей
check_dependencies() {
    if ! command -v jq &> /dev/null; then
        echo -e "${RED}Ошибка: jq не установлен${NC}"
        echo -e "${YELLOW}Установите: sudo apt-get install jq${NC}"
        exit 1
    fi
}

# Функция определения категории по паттерну
detect_category() {
    local text="$1"
    local text_lower=$(echo "$text" | tr '[:upper:]' '[:lower:]')
    
    if [[ "$text_lower" =~ (git|branch|commit|merge|rebase|checkout) ]]; then
        echo "Git"
    elif [[ "$text_lower" =~ (quality|gate|check|validate|spec) ]]; then
        echo "Quality Gates"
    elif [[ "$text_lower" =~ (agent|worker|orchestrator|task) ]]; then
        echo "Агенты"
    elif [[ "$text_lower" =~ (test|assert|expect|coverage|tdd) ]]; then
        echo "TDD"
    elif [[ "$text_lower" =~ (mcp|server|context|documentation) ]]; then
        echo "MCP"
    elif [[ "$text_lower" =~ (build|compile|cargo|npm|dependency|install) ]]; then
        echo "Сборка"
    else
        echo "Другое"
    fi
}

# Функция генерации ID ошибки
generate_error_id() {
    local category="$1"
    local existing_count="$2"
    
    local prefix=""
    case "$category" in
        "Git") prefix="ERR-GIT" ;;
        "Quality Gates") prefix="ERR-QG" ;;
        "Агенты") prefix="ERR-AGENT" ;;
        "TDD") prefix="ERR-TDD" ;;
        "MCP") prefix="ERR-MCP" ;;
        "Сборка") prefix="ERR-BUILD" ;;
        *) prefix="ERR-OTHER" ;;
    esac
    
    printf "%s-%03d" "$prefix" "$((existing_count + 1))"
}

# Функция извлечения ошибок из error-handling-examples.md
extract_from_source() {
    echo -e "${CYAN}Извлечение ошибок из источника: $SOURCE_FILE${NC}"
    
    if [[ ! -f "$SOURCE_FILE" ]]; then
        echo -e "${RED}Ошибка: Файл источника не найден: $SOURCE_FILE${NC}"
        return 1
    fi
    
    # Создаем временный файл для ошибок
    local temp_errors=$(mktemp)
    
    # Парсим файл и извлекаем секции ошибок
    local in_error=false
    local current_id=""
    local current_title=""
    local current_pattern=""
    local current_cause=""
    local current_solution=""
    local current_prevention=""
    local section_num=0
    local error_count=0
    
    while IFS= read -r line || [[ -n "$line" ]]; do
        # Проверка на заголовок секции ошибки
        if [[ "$line" =~ ^##\ [0-9]+\.\ (.+)$ ]]; then
            # Сохраняем предыдущую ошибку если есть
            if [[ "$in_error" == true && -n "$current_title" ]]; then
                save_error "$current_id" "$current_title" "$current_pattern" "$current_cause" "$current_solution" "$current_prevention" "$section_num" >> "$temp_errors"
                ((error_count++))
            fi
            
            ((section_num++))
            in_error=true
            current_title="${BASH_REMATCH[1]}"
            current_pattern=""
            current_cause=""
            current_solution=""
            current_prevention=""
            
            # Определяем категорию и генерируем ID
            local category=$(detect_category "$current_title")
            current_id=$(generate_error_id "$category" "$error_count")
            
        elif [[ "$in_error" == true ]]; then
            # Извлекаем **Причина:**
            if [[ "$line" =~ ^\*\*Причина:\*\*[[:space:]]*(.*)$ ]]; then
                current_cause="${BASH_REMATCH[1]}"
            # Извлекаем **Решение:**
            elif [[ "$line" =~ ^\*\*Решение:\*\*[[:space:]]*(.*)$ ]]; then
                current_solution="${BASH_REMATCH[1]}"
            # Извлекаем **Профилактика:**
            elif [[ "$line" =~ ^\*\*Профилактика:\*\*[[:space:]]*(.*)$ ]]; then
                current_prevention="${BASH_REMATCH[1]}"
            # Извлекаем паттерн из блока кода
            elif [[ "$line" =~ ^[[:space:]]*(❌|⚠️)[[:space:]]*(.+)$ ]]; then
                if [[ -z "$current_pattern" ]]; then
                    current_pattern="${BASH_REMATCH[2]}"
                fi
            fi
        fi
    done < "$SOURCE_FILE"
    
    # Сохраняем последнюю ошибку
    if [[ "$in_error" == true && -n "$current_title" ]]; then
        save_error "$current_id" "$current_title" "$current_pattern" "$current_cause" "$current_solution" "$current_prevention" "$section_num" >> "$temp_errors"
        ((error_count++))
    fi
    
    echo -e "${GREEN}Извлечено ошибок: $error_count${NC}"
    echo "$temp_errors"
}

# Функция сохранения ошибки в JSON формат
save_error() {
    local id="$1"
    local title="$2"
    local pattern="$3"
    local cause="$4"
    local solution="$5"
    local prevention="$6"
    local section="$7"
    
    local category=$(detect_category "$title")
    
    # Извлекаем ключевые слова из заголовка и описания
    local keywords=$(echo "$title $cause" | tr '[:upper:]' '[:lower:]' | tr -cs '[:alnum:]' '\n' | sort -u | tr '\n' ',' | sed 's/,$//' | sed 's/,/, /g')
    
    cat << EOF
{
  "id": "$id",
  "category": "$category",
  "title": "$title",
  "pattern": "$pattern",
  "cause": "$cause",
  "solution": "$solution",
  "prevention": "$prevention",
  "file": "error-handling-examples.md",
  "section": $section,
  "keywords": [$(echo "$keywords" | sed 's/\([^,]*\)/"\1"/g')]
}
EOF
}

# Функция пересоздания индекса
rebuild_index() {
    echo -e "${CYAN}Пересоздание индекса ошибок...${NC}"
    
    local temp_errors=$(extract_from_source)
    
    if [[ ! -f "$temp_errors" || -z "$(cat "$temp_errors")" ]]; then
        echo -e "${RED}Ошибка: Не удалось извлечь ошибки из источника${NC}"
        rm -f "$temp_errors"
        return 1
    fi
    
    # Создаем новый индекс
    local timestamp=$(date -Iseconds)
    local error_count=$(jq -s 'length' "$temp_errors")
    
    # Формируем финальный JSON
    jq -n --argjson errors "$(jq -s '.' "$temp_errors")" --arg ts "$timestamp" --argjson count "$error_count" '{
        "metadata": {
            "version": "1.0.0",
            "created": ($ts | split("T")[0]),
            "updated": $ts,
            "source": "error-handling-examples.md",
            "total_errors": $count
        },
        "categories": ["Git", "Quality Gates", "Агенты", "TDD", "MCP", "Сборка"],
        "errors": $errors
    }' > "$INDEX_FILE"
    
    rm -f "$temp_errors"
    
    echo -e "${GREEN}Индекс создан: $INDEX_FILE${NC}"
    echo -e "${GREEN}Всего ошибок: $error_count${NC}"
}

# Функция добавления ошибок из файла логов
add_from_log() {
    local log_file="$1"
    
    echo -e "${CYAN}Добавление ошибок из лога: $log_file${NC}"
    
    if [[ ! -f "$log_file" ]]; then
        echo -e "${RED}Ошибка: Файл лога не найден: $log_file${NC}"
        return 1
    fi
    
    # Ищем паттерны ошибок в логе
    local errors_found=0
    
    while IFS= read -r line; do
        if [[ "$line" =~ (❌|ERROR|FATAL|FAILED) ]]; then
            echo -e "${YELLOW}Найдена ошибка: $line${NC}"
            ((errors_found++))
            
            # Здесь можно добавить логику для автоматического добавления в базу
            # Для простоты просто логируем находки
        fi
    done < "$log_file"
    
    echo -e "${GREEN}Найдено ошибок в логе: $errors_found${NC}"
}

# Функция сканирования директории
scan_directory() {
    local dir="$1"
    
    echo -e "${CYAN}Сканирование директории: $dir${NC}"
    
    if [[ ! -d "$dir" ]]; then
        echo -e "${RED}Ошибка: Директория не найдена: $dir${NC}"
        return 1
    fi
    
    local total_errors=0
    local files_scanned=0
    
    # Ищем файлы логов и отчетов
    while IFS= read -r -d '' file; do
        ((files_scanned++))
        
        # Подсчет ошибок в файле
        local file_errors=$(grep -c -E '(❌|ERROR|FATAL|FAILED)' "$file" 2>/dev/null || echo "0")
        
        if [[ "$file_errors" -gt 0 ]]; then
            echo -e "${YELLOW}$file: $file_errors ошибок${NC}"
            ((total_errors += file_errors))
        fi
    done < <(find "$dir" -type f \( -name "*.log" -o -name "*.md" -o -name "*.txt" -o -name "*.json" \) -print0 2>/dev/null)
    
    echo ""
    echo -e "${GREEN}Просканировано файлов: $files_scanned${NC}"
    echo -e "${GREEN}Всего ошибок найдено: $total_errors${NC}"
}

# Функция валидации индекса
validate_index() {
    echo -e "${CYAN}Валидация индекса: $INDEX_FILE${NC}"
    
    if [[ ! -f "$INDEX_FILE" ]]; then
        echo -e "${RED}Ошибка: Индекс не найден${NC}"
        return 1
    fi
    
    # Проверка JSON синтаксиса
    if ! jq empty "$INDEX_FILE" 2>/dev/null; then
        echo -e "${RED}Ошибка: Неверный JSON формат${NC}"
        return 1
    fi
    
    # Проверка структуры
    local has_metadata=$(jq 'has("metadata")' "$INDEX_FILE")
    local has_errors=$(jq 'has("errors")' "$INDEX_FILE")
    local has_categories=$(jq 'has("categories")' "$INDEX_FILE")
    
    if [[ "$has_metadata" != "true" || "$has_errors" != "true" || "$has_categories" != "true" ]]; then
        echo -e "${RED}Ошибка: Отсутствуют обязательные поля${NC}"
        return 1
    fi
    
    # Проверка каждого error
    local invalid_errors=$(jq '[.errors[] | select(
        (has("id") | not) or
        (has("category") | not) or
        (has("title") | not) or
        (has("pattern") | not) or
        (has("cause") | not) or
        (has("solution") | not) or
        (has("prevention") | not)
    )] | length' "$INDEX_FILE")
    
    if [[ "$invalid_errors" -gt 0 ]]; then
        echo -e "${RED}Ошибка: $invalid_errors ошибок имеют неполную структуру${NC}"
        return 1
    fi
    
    # Проверка уникальности ID
    local unique_count=$(jq '[.errors[].id] | unique | length' "$INDEX_FILE")
    local total_count=$(jq '.errors | length' "$INDEX_FILE")
    
    if [[ "$unique_count" != "$total_count" ]]; then
        echo -e "${RED}Ошибка: Обнаружены дублирующиеся ID${NC}"
        return 1
    fi
    
    echo -e "${GREEN}✅ Индекс валиден${NC}"
    echo -e "${GREEN}Всего ошибок: $total_count${NC}"
    echo -e "${GREEN}Уникальных ID: $unique_count${NC}"
}

# Функция статистики
show_stats() {
    echo -e "${CYAN}Статистика автообучения:${NC}"
    echo "=========================================="
    
    if [[ ! -f "$INDEX_FILE" ]]; then
        echo -e "${YELLOW}Индекс еще не создан. Запустите --rebuild${NC}"
        return
    fi
    
    local total=$(jq '.errors | length' "$INDEX_FILE")
    local version=$(jq -r '.metadata.version' "$INDEX_FILE")
    local created=$(jq -r '.metadata.created' "$INDEX_FILE")
    local updated=$(jq -r '.metadata.updated // "N/A"' "$INDEX_FILE")
    
    echo -e "${GREEN}Версия:${NC} $version"
    echo -e "${GREEN}Создана:${NC} $created"
    echo -e "${GREEN}Обновлен:${NC} $updated"
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
    echo -e "${YELLOW}Последние добавленные:${NC}"
    jq -r '.errors[-5:] | .[] | "  \(.id): \(.title)"' "$INDEX_FILE"
}

# Основная функция
main() {
    check_dependencies
    
    # Создаем директорию для обученных данных если нет
    mkdir -p "$LEARNED_DIR"
    
    case "${1:-}" in
        --rebuild)
            rebuild_index
            ;;
        --add)
            if [[ -z "${2:-}" ]]; then
                echo -e "${RED}Ошибка: Укажите файл лога${NC}"
                exit 1
            fi
            add_from_log "$2"
            ;;
        --scan)
            if [[ -z "${2:-}" ]]; then
                echo -e "${RED}Ошибка: Укажите директорию${NC}"
                exit 1
            fi
            scan_directory "$2"
            ;;
        --validate)
            validate_index
            ;;
        --stats)
            show_stats
            ;;
        --help|-h)
            show_help
            ;;
        "")
            # Режим по умолчанию: rebuild если индекса нет, иначе stats
            if [[ ! -f "$INDEX_FILE" ]]; then
                echo -e "${CYAN}Индекс не найден. Запускаю пересоздание...${NC}"
                rebuild_index
            else
                show_stats
                echo ""
                echo -e "${CYAN}Запустите --rebuild для обновления из источника${NC}"
            fi
            ;;
        *)
            echo -e "${RED}Неизвестная команда: $1${NC}"
            show_help
            exit 1
            ;;
    esac
}

# Запуск
main "$@"
