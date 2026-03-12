#!/bin/bash
# Скрипт проверки соответствия YAML-заголовков стандартам
# Назначение: Проверка корректности YAML заголовков в агентах и навыках

set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Проверка аргументов
if [ $# -eq 0 ]; then
    SEARCH_PATHS=(".qwen/agents/" ".qwen/skills/")
else
    SEARCH_PATHS=("$@")
fi

log_info "Проверка YAML заголовков в следующих директориях: ${SEARCH_PATHS[*]}"

FAILED_CHECKS=0
TOTAL_FILES=0

# Функция проверки одного файла
check_yaml_header() {
    local file="$1"
    local filename=$(basename "$file")
    
    # Проверяем, что файл имеет расширение .md
    if [[ "$filename" != *.md ]]; then
        return 0
    fi
    
    TOTAL_FILES=$((TOTAL_FILES + 1))
    
    log_info "Проверка файла: $file"
    
    # Проверяем, что файл существует
    if [ ! -f "$file" ]; then
        log_error "Файл не существует: $file"
        FAILED_CHECKS=$((FAILED_CHECKS + 1))
        return 1
    fi
    
    # Извлекаем содержимое YAML заголовка (между --- в начале файла)
    local yaml_content=$(sed -n '/^---$/,/^---$/{ /^---$/!p; }' "$file" | head -n -1)
    
    if [ -z "$yaml_content" ]; then
        log_error "YAML заголовок не найден в файле: $file"
        FAILED_CHECKS=$((FAILED_CHECKS + 1))
        return 1
    fi
    
    # Проверяем обязательные поля
    local missing_fields=()
    
    # Проверяем наличие поля name
    if ! echo "$yaml_content" | grep -q "^name:"; then
        missing_fields+=("name")
    fi
    
    # Проверяем наличие поля description
    if ! echo "$yaml_content" | grep -q "^description:"; then
        missing_fields+=("description")
    fi
    
    # Проверяем наличие поля color (для агентов)
    if [[ "$file" == *".qwen/agents/"* ]]; then
        if ! echo "$yaml_content" | grep -q "^color:"; then
            missing_fields+=("color")
        fi
    fi
    
    # Проверяем, что поле tools есть для агентов
    if [[ "$file" == *".qwen/agents/"* ]]; then
        if ! echo "$yaml_content" | grep -q "^tools:"; then
            missing_fields+=("tools")
        else
            # Проверяем, что tools - это список
            local tools_line=$(echo "$yaml_content" | grep "^tools:")
            if [[ ! "$tools_line" =~ ^tools:\ *$ ]] && [[ ! "$tools_line" =~ ^tools:\ \-$ ]]; then
                log_error "Поле tools должно быть пустым списком или начинаться с дефиса в файле: $file"
                FAILED_CHECKS=$((FAILED_CHECKS + 1))
                return 1
            fi
        fi
    fi
    
    if [ ${#missing_fields[@]} -ne 0 ]; then
        log_error "Отсутствуют обязательные поля в YAML заголовке: ${missing_fields[*]} в файле: $file"
        FAILED_CHECKS=$((FAILED_CHECKS + 1))
        return 1
    fi
    
    # Проверяем формат поля name
    local name_value=$(echo "$yaml_content" | grep "^name:" | sed 's/^name:[[:space:]]*//' | sed 's/[[:space:]]*$//')
    if [ -n "$name_value" ]; then
        # Проверяем, что имя соответствует формату (для агентов)
        if [[ "$file" == *".qwen/agents/"* ]]; then
            if [[ ! "$name_value" =~ ^(orc_|work_) ]]; then
                log_error "Имя агента должно начинаться с 'orc_' или 'work_' в файле: $file"
                FAILED_CHECKS=$((FAILED_CHECKS + 1))
                return 1
            fi
        fi
        
        # Проверяем, что имя использует kebab-case
        if [[ "$name_value" =~ [A-Z] ]] || [[ "$name_value" =~ _ ]]; then
            log_warning "Имя должно использовать kebab-case (например: my-agent-name) в файле: $file"
        fi
    fi
    
    # Проверяем формат поля description
    local desc_value=$(echo "$yaml_content" | grep "^description:" | sed 's/^description:[[:space:]]*//' | sed 's/[[:space:]]*$//')
    if [ -z "$desc_value" ]; then
        log_error "Поле description пустое в файле: $file"
        FAILED_CHECKS=$((FAILED_CHECKS + 1))
        return 1
    fi
    
    # Проверяем, что description не слишком короткое
    if [ ${#desc_value} -lt 10 ]; then
        log_error "Поле description слишком короткое в файле: $file"
        FAILED_CHECKS=$((FAILED_CHECKS + 1))
        return 1
    fi
    
    # Для агентов проверяем формат поля color
    if [[ "$file" == *".qwen/agents/"* ]]; then
        local color_value=$(echo "$yaml_content" | grep "^color:" | sed 's/^color:[[:space:]]*//' | sed 's/[[:space:]]*$//')
        if [ -z "$color_value" ]; then
            log_error "Поле color пустое в файле: $file"
            FAILED_CHECKS=$((FAILED_CHECKS + 1))
            return 1
        fi
        
        # Проверяем, что цвет в нижнем регистре
        if [[ "$color_value" =~ [A-Z] ]]; then
            log_error "Поле color должно быть в нижнем регистре в файле: $file"
            FAILED_CHECKS=$((FAILED_CHECKS + 1))
            return 1
        fi
    fi
    
    # Проверяем, что YAML заголовок находится в начале файла
    local first_line=$(head -n 1 "$file")
    if [ "$first_line" != "---" ]; then
        log_error "YAML заголовок должен начинаться с первой строки в файле: $file"
        FAILED_CHECKS=$((FAILED_CHECKS + 1))
        return 1
    fi
    
    log_success "YAML заголовок корректен в файле: $file"
    return 0
}

# Поиск и проверка файлов
for search_path in "${SEARCH_PATHS[@]}"; do
    if [ -d "$search_path" ]; then
        # Ищем все .md файлы в директории
        while IFS= read -r -d '' file; do
            check_yaml_header "$file"
        done < <(find "$search_path" -name "*.md" -print0)
    else
        log_warning "Директория не найдена: $search_path"
    fi
done

# Вывод итогов
log_info "Проверка завершена. Всего файлов проверено: $TOTAL_FILES"
if [ $FAILED_CHECKS -eq 0 ]; then
    log_success "Все YAML заголовки соответствуют стандартам"
    exit 0
else
    log_error "Обнаружено $FAILED_CHECKS ошибок в YAML заголовках"
    exit 1
fi