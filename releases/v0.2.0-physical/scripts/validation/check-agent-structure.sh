#!/bin/bash
# Скрипт проверки структуры агентов
# Назначение: Проверка корректности структуры файлов агентов (оркестраторов и воркеров)

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
    SEARCH_PATH=".qwen/agents/"
else
    SEARCH_PATH="$1"
fi

log_info "Проверка структуры агентов в директории: $SEARCH_PATH"

FAILED_CHECKS=0
TOTAL_AGENTS=0

# Функция проверки структуры одного агента
check_agent_structure() {
    local file="$1"
    local filename=$(basename "$file" .md)
    
    TOTAL_AGENTS=$((TOTAL_AGENTS + 1))
    
    log_info "Проверка структуры агента: $filename"
    
    # Проверяем, что файл существует
    if [ ! -f "$file" ]; then
        log_error "Файл агента не существует: $file"
        FAILED_CHECKS=$((FAILED_CHECKS + 1))
        return 1
    fi
    
    # Проверяем, что имя файла соответствует формату
    if [[ ! "$filename" =~ ^(orc_|work_) ]]; then
        log_error "Имя агента не соответствует формату (должно начинаться с 'orc_' или 'work_'): $filename"
        FAILED_CHECKS=$((FAILED_CHECKS + 1))
        return 1
    fi
    
    # Проверяем, что имя содержит домен (вторая часть после первого подчеркивания)
    local parts=(${filename//_/ })
    if [ ${#parts[@]} -lt 3 ]; then
        log_error "Имя агента должно содержать тип_домен_имя: $filename"
        FAILED_CHECKS=$((FAILED_CHECKS + 1))
        return 1
    fi
    
    # Проверяем, что домен в имени агента допустим
    local domain="${parts[1]}"
    local valid_domains=("dev" "frontend" "backend" "testing" "research" "security" "planning")
    local is_valid_domain=false
    
    for valid_domain in "${valid_domains[@]}"; do
        if [ "$domain" == "$valid_domain" ]; then
            is_valid_domain=true
            break
        fi
    done
    
    if [ "$is_valid_domain" = false ]; then
        log_warning "Домен '$domain' в имени агента '$filename' может быть недопустимым. Допустимые домены: ${valid_domains[*]}"
    fi
    
    # Проверяем содержимое файла
    local content=$(cat "$file")
    
    # Проверяем, что файл содержит YAML заголовок
    if ! echo "$content" | head -n 10 | grep -q "^---$"; then
        log_error "YAML заголовок не найден в файле: $file"
        FAILED_CHECKS=$((FAILED_CHECKS + 1))
        return 1
    fi
    
    # Проверяем, что файл содержит обязательные разделы
    local required_sections=("## Назначение" "## Инструкции")
    
    for section in "${required_sections[@]}"; do
        if ! echo "$content" | grep -q "$section"; then
            log_error "Раздел '$section' отсутствует в файле: $file"
            FAILED_CHECKS=$((FAILED_CHECKS + 1))
            return 1
        fi
    done
    
    # Проверяем, что раздел "Назначение" не пустой
    local naznachenie_start=$(echo "$content" | grep -n "## Назначение" | cut -d: -f1)
    local next_section_start=$(echo "$content" | sed -n "$((naznachenie_start + 1)),\$p" | grep -n "^## " | head -n1 | cut -d: -f1)
    
    if [ -n "$next_section_start" ]; then
        local naznachenie_end=$((naznachenie_start + next_section_start - 1))
    else
        local naznachenie_end=$(echo "$content" | wc -l)
    fi
    
    local naznachenie_content=$(echo "$content" | sed -n "$((naznachenie_start + 1)),$((naznachenie_end - 1))p" | tr -d '\n\r\t' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    
    if [ -z "$naznachenie_content" ] || [ ${#naznachenie_content} -lt 10 ]; then
        log_error "Раздел 'Назначение' слишком короткий или пустой в файле: $file"
        FAILED_CHECKS=$((FAILED_CHECKS + 1))
        return 1
    fi
    
    # Проверяем, что раздел "Инструкции" содержит фазы
    local instructions_start=$(echo "$content" | grep -n "## Инструкции" | cut -d: -f1)
    local instructions_next_section=$(echo "$content" | sed -n "$((instructions_start + 1)),\$p" | grep -n "^## " | head -n1 | cut -d: -f1)
    
    if [ -n "$instructions_next_section" ]; then
        local instructions_end=$((instructions_start + instructions_next_section - 1))
    else
        local instructions_end=$(echo "$content" | wc -l)
    fi
    
    local instructions_content=$(echo "$content" | sed -n "$((instructions_start + 1)),$((instructions_end - 1))p")
    
    # Проверяем, что в инструкциях есть хотя бы одна фаза (например, "Фаза 1:")
    if ! echo "$instructions_content" | grep -q "Фаза [0-9]\+:"; then
        log_warning "В разделе 'Инструкции' не найдены фазы выполнения в файле: $file"
    fi
    
    # Проверяем, что файл содержит стандартизированную отчетность
    if ! echo "$content" | grep -q "## Стандартизированная отчетность"; then
        log_warning "Раздел 'Стандартизированная отчетность' отсутствует в файле: $file"
    fi
    
    # Проверяем, что файл содержит интеграцию навыков
    if ! echo "$content" | grep -q "## Интеграция навыков"; then
        log_warning "Раздел 'Интеграция навыков' отсутствует в файле: $file"
    fi
    
    # Для оркестраторов проверяем наличие шаблона возврата управления
    if [[ "$filename" == orc_* ]]; then
        if ! echo "$content" | grep -q "## Шаблон возврата управления"; then
            log_warning "Раздел 'Шаблон возврата управления' отсутствует в оркестраторе: $file"
        fi
    fi
    
    # Проверяем, что файл содержит формат файла плана
    if ! echo "$content" | grep -q "## Формат файла плана"; then
        log_warning "Раздел 'Формат файла плана' отсутствует в файле: $file"
    fi
    
    log_success "Структура агента корректна: $filename"
    return 0
}

# Поиск и проверка файлов агентов
if [ -d "$SEARCH_PATH" ]; then
    # Ищем все .md файлы в директории агентов
    while IFS= read -r -d '' file; do
        # Проверяем, что это файл агента (не поддиректория)
        if [ -f "$file" ]; then
            check_agent_structure "$file"
        fi
    done < <(find "$SEARCH_PATH" -name "*.md" -print0)
else
    log_error "Директория агентов не найдена: $SEARCH_PATH"
    exit 1
fi

# Вывод итогов
log_info "Проверка структуры агентов завершена. Всего агентов проверено: $TOTAL_AGENTS"
if [ $FAILED_CHECKS -eq 0 ]; then
    log_success "Все агенты соответствуют структурным стандартам"
    exit 0
else
    log_error "Обнаружено $FAILED_CHECKS ошибок в структуре агентов"
    exit 1
fi