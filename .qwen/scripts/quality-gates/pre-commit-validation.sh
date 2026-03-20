#!/bin/bash
# =============================================================================
# Скрипт: .qwen/scripts/quality-gates/pre-commit-validation.sh
# Назначение: Автоматическая валидация файлов перед коммитом
# =============================================================================
# Проверки:
# - Синтаксис Python (python -m py_compile)
# - Синтаксис Bash (bash -n)
# - Линтинг Markdown (markdownlint)
# - Валидация JSON (jq или python -m json.tool)
# - Валидация YAML (python -c "import yaml")
#
# Использование:
#   .qwen/scripts/quality-gates/pre-commit-validation.sh
#   .qwen/scripts/quality-gates/pre-commit-validation.sh --verbose
#
# Выход:
#   0 - Все проверки пройдены
#   1 - Валидация не пройдена
# =============================================================================

set -o pipefail

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Флаги
VERBOSE=false
ERRORS=()
WARNINGS=()

# Счетчики
PYTHON_FILES=0
PYTHON_ERRORS=0
BASH_FILES=0
BASH_ERRORS=0
MARKDOWN_FILES=0
MARKDOWN_ERRORS=0
JSON_FILES=0
JSON_ERRORS=0
YAML_FILES=0
YAML_ERRORS=0

# =============================================================================
# Функции
# =============================================================================

print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  Pre-Commit Валидация${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
    ERRORS+=("$1")
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
    WARNINGS+=("$1")
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

print_verbose() {
    if [ "$VERBOSE" = true ]; then
        echo "  $1"
    fi
}

# Получить список измененных файлов
get_changed_files() {
    # Проверяем staged файлы
    local staged_files=$(git diff --cached --name-only 2>/dev/null)
    
    # Если нет staged файлов, проверяем измененные
    if [ -z "$staged_files" ]; then
        staged_files=$(git diff --name-only 2>/dev/null)
    fi
    
    # Если все еще пусто, проверяем все файлы в репозитории
    if [ -z "$staged_files" ]; then
        staged_files=$(git ls-files 2>/dev/null)
    fi
    
    echo "$staged_files"
}

# Проверка синтаксиса Python
validate_python() {
    local file="$1"
    
    if [ ! -f "$file" ]; then
        return 0
    fi
    
    print_verbose "Проверка Python: $file"
    
    local output
    output=$(python -m py_compile "$file" 2>&1)
    local status=$?
    
    if [ $status -ne 0 ]; then
        print_error "Python: Ошибка в $file"
        print_verbose "$output"
        ((PYTHON_ERRORS++))
        return 1
    fi
    
    ((PYTHON_FILES++))
    return 0
}

# Проверка синтаксиса Bash
validate_bash() {
    local file="$1"
    
    if [ ! -f "$file" ]; then
        return 0
    fi
    
    print_verbose "Проверка Bash: $file"
    
    local output
    output=$(bash -n "$file" 2>&1)
    local status=$?
    
    if [ $status -ne 0 ]; then
        print_error "Bash: Ошибка в $file"
        print_verbose "$output"
        ((BASH_ERRORS++))
        return 1
    fi
    
    ((BASH_FILES++))
    return 0
}

# Линтинг Markdown
validate_markdown() {
    local file="$1"
    
    if [ ! -f "$file" ]; then
        return 0
    fi
    
    print_verbose "Проверка Markdown: $file"
    
    # Проверяем наличие markdownlint
    if command -v markdownlint &> /dev/null; then
        local output
        output=$(markdownlint "$file" 2>&1)
        local status=$?
        
        if [ $status -ne 0 ] && [ -n "$output" ]; then
            # Игнорируем предупреждения, считаем только ошибки
            if echo "$output" | grep -q "error"; then
                print_error "Markdown: Ошибка в $file"
                print_verbose "$output"
                ((MARKDOWN_ERRORS++))
                return 1
            else
                print_verbose "Markdown: Предупреждения в $file"
                print_verbose "$output"
            fi
        fi
    else
        # Если markdownlint не установлен, используем простую проверку
        # Проверяем базовую структуру
        if grep -q "^#\{7,\}" "$file" 2>/dev/null; then
            print_warning "Markdown: Возможная проблема с заголовками в $file (слишком глубокая вложенность)"
        fi
    fi
    
    ((MARKDOWN_FILES++))
    return 0
}

# Валидация JSON
validate_json() {
    local file="$1"
    
    if [ ! -f "$file" ]; then
        return 0
    fi
    
    print_verbose "Проверка JSON: $file"
    
    local output
    local status
    
    # Пробуем через jq (быстрее и информативнее)
    if command -v jq &> /dev/null; then
        output=$(jq empty "$file" 2>&1)
        status=$?
    else
        # Фоллбэк на python
        output=$(python -m json.tool "$file" > /dev/null 2>&1)
        status=$?
    fi
    
    if [ $status -ne 0 ]; then
        print_error "JSON: Ошибка в $file"
        print_verbose "$output"
        ((JSON_ERRORS++))
        return 1
    fi
    
    ((JSON_FILES++))
    return 0
}

# Валидация YAML
validate_yaml() {
    local file="$1"
    
    if [ ! -f "$file" ]; then
        return 0
    fi
    
    print_verbose "Проверка YAML: $file"
    
    # Проверяем наличие Python и PyYAML
    if command -v python &> /dev/null; then
        local output
        output=$(python -c "import yaml; yaml.safe_load(open('$file'))" 2>&1)
        local status=$?
        
        if [ $status -ne 0 ]; then
            print_error "YAML: Ошибка в $file"
            print_verbose "$output"
            ((YAML_ERRORS++))
            return 1
        fi
    else
        print_warning "YAML: Python не найден, пропускаем проверку $file"
        ((YAML_FILES++))
        return 0
    fi
    
    ((YAML_FILES++))
    return 0
}

# Основная функция валидации
run_validation() {
    local files="$1"
    
    print_info "Анализ файлов..."
    echo ""
    
    while IFS= read -r file; do
        [ -z "$file" ] && continue
        [ ! -f "$file" ] && continue
        
        # Определяем тип файла и запускаем соответствующую проверку
        case "$file" in
            *.py)
                validate_python "$file"
                ;;
            *.sh|*.bash)
                validate_bash "$file"
                ;;
            *.md|*.markdown)
                validate_markdown "$file"
                ;;
            *.json)
                validate_json "$file"
                ;;
            *.yaml|*.yml)
                validate_yaml "$file"
                ;;
            *)
                print_verbose "Пропущен файл (неподдерживаемый тип): $file"
                ;;
        esac
    done <<< "$files"
}

# Вывод итогов
print_summary() {
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  Итоги валидации${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
    
    # Python
    if [ $PYTHON_FILES -gt 0 ]; then
        if [ $PYTHON_ERRORS -eq 0 ]; then
            print_success "Python: $PYTHON_FILES файлов проверено"
        else
            print_error "Python: $PYTHON_ERRORS ошибок в $PYTHON_FILES файлах"
        fi
    fi
    
    # Bash
    if [ $BASH_FILES -gt 0 ]; then
        if [ $BASH_ERRORS -eq 0 ]; then
            print_success "Bash: $BASH_FILES файлов проверено"
        else
            print_error "Bash: $BASH_ERRORS ошибок в $BASH_FILES файлах"
        fi
    fi
    
    # Markdown
    if [ $MARKDOWN_FILES -gt 0 ]; then
        if [ $MARKDOWN_ERRORS -eq 0 ]; then
            print_success "Markdown: $MARKDOWN_FILES файлов проверено"
        else
            print_error "Markdown: $MARKDOWN_ERRORS ошибок в $MARKDOWN_FILES файлах"
        fi
    fi
    
    # JSON
    if [ $JSON_FILES -gt 0 ]; then
        if [ $JSON_ERRORS -eq 0 ]; then
            print_success "JSON: $JSON_FILES файлов проверено"
        else
            print_error "JSON: $JSON_ERRORS ошибок в $JSON_FILES файлах"
        fi
    fi
    
    # YAML
    if [ $YAML_FILES -gt 0 ]; then
        if [ $YAML_ERRORS -eq 0 ]; then
            print_success "YAML: $YAML_FILES файлов проверено"
        else
            print_error "YAML: $YAML_ERRORS ошибок в $YAML_FILES файлах"
        fi
    fi
    
    echo ""
    
    # Общий итог
    local total_errors=$((PYTHON_ERRORS + BASH_ERRORS + MARKDOWN_ERRORS + JSON_ERRORS + YAML_ERRORS))
    
    if [ $total_errors -eq 0 ]; then
        echo -e "${GREEN}✅ Все проверки пройдены${NC}"
        
        if [ ${#WARNINGS[@]} -gt 0 ]; then
            echo ""
            echo -e "${YELLOW}Предупреждений: ${#WARNINGS[@]}${NC}"
        fi
        
        return 0
    else
        echo -e "${RED}❌ Валидация не пройдена${NC}"
        echo -e "${RED}Всего ошибок: $total_errors${NC}"
        
        if [ "$VERBOSE" = true ] && [ ${#ERRORS[@]} -gt 0 ]; then
            echo ""
            echo -e "${RED}Список ошибок:${NC}"
            for error in "${ERRORS[@]}"; do
                echo "  - $error"
            done
        fi
        
        return 1
    fi
}

# Показать справку
show_help() {
    echo "Pre-Commit Валидация - Автоматическая проверка файлов перед коммитом"
    echo ""
    echo "Использование:"
    echo "  $0 [OPTIONS]"
    echo ""
    echo "Опции:"
    echo "  --verbose, -v    Подробный вывод с деталями проверок"
    echo "  --help, -h       Показать эту справку"
    echo ""
    echo "Проверки:"
    echo "  - Синтаксис Python (python -m py_compile)"
    echo "  - Синтаксис Bash (bash -n)"
    echo "  - Линтинг Markdown (markdownlint)"
    echo "  - Валидация JSON (jq или python -m json.tool)"
    echo "  - Валидация YAML (python + PyYAML)"
    echo ""
    echo "Выходные коды:"
    echo "  0 - Все проверки пройдены"
    echo "  1 - Валидация не пройдена"
    echo ""
}

# =============================================================================
# Основная логика
# =============================================================================

main() {
    # Парсинг аргументов
    while [[ $# -gt 0 ]]; do
        case $1 in
            --verbose|-v)
                VERBOSE=true
                shift
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            *)
                echo "Неизвестная опция: $1"
                echo "Используйте --help для справки"
                exit 1
                ;;
        esac
    done
    
    print_header
    
    # Проверка наличия git
    if ! command -v git &> /dev/null; then
        print_error "Git не найден. Установите git для работы скрипта."
        exit 1
    fi
    
    # Проверка наличия Python
    if ! command -v python &> /dev/null && ! command -v python3 &> /dev/null; then
        print_warning "Python не найден. Проверки Python и YAML будут пропущены."
    fi
    
    # Получение списка измененных файлов
    local changed_files
    changed_files=$(get_changed_files)
    
    if [ -z "$changed_files" ]; then
        print_info "Нет измененных файлов для проверки"
        echo ""
        echo -e "${GREEN}✅ Валидация пройдена (нет файлов для проверки)${NC}"
        exit 0
    fi
    
    # Запуск валидации
    run_validation "$changed_files"
    
    # Вывод итогов
    local result
    print_summary
    result=$?
    
    exit $result
}

# Запуск основной функции
main "$@"
