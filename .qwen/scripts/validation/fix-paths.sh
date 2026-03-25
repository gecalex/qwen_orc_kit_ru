#!/bin/bash

# =============================================================================
# fix-paths.sh - Автоматическое исправление путей в документации
# =============================================================================
# Назначение: Исправление некорректных путей в markdown файлах проекта
# 
# Замены:
#   - `.qwen/.qwen/` → `.qwen/`
#   - `.specify/` → `.qwen/specify/`
#   - `specs/` → `.qwen/specify/specs/`
#   - `.qwen/specify/specs/` → `specs/` (если нужно)
#
# Использование:
#   .qwen/scripts/validation/fix-paths.sh --dry-run  # Предварительный просмотр
#   .qwen/scripts/validation/fix-paths.sh --fix      # Исправить
# =============================================================================

set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Переменные
DRY_RUN=false
FIX=false
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
REPORT_FILE="${PROJECT_ROOT}/.qwen/reports/validation/fix-paths-$(date +%Y%m%d-%H%M%S).md"
TOTAL_FILES=0
TOTAL_CHANGES=0
MODIFIED_FILES=0

# Функция вывода помощи
show_help() {
    echo -e "${BLUE}fix-paths.sh - Исправление путей в документации${NC}"
    echo ""
    echo "Использование:"
    echo "  $0 --dry-run    Предварительный просмотр изменений"
    echo "  $0 --fix        Исправить файлы"
    echo "  $0 --help       Показать эту справку"
    echo ""
    echo "Примеры:"
    echo "  $0 --dry-run"
    echo "  $0 --fix"
}

# Функция логирования
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

# Функция поиска markdown файлов
find_md_files() {
    find "${PROJECT_ROOT}" -type f -name "*.md" \
        -not -path "*/node_modules/*" \
        -not -path "*/.git/*" \
        -not -path "*/state/*" \
        -not -path "*/reports/*"
}

# Функция проверки файла на наличие некорректных путей
# Возвращает только число изменений
check_file() {
    local file="$1"
    local changes=0
    local count=0
    
    # Проверка на `.qwen/.qwen/`
    if grep -q '\.qwen/\.qwen/' "$file" 2>/dev/null; then
        count=$(grep -c '\.qwen/\.qwen/' "$file" 2>/dev/null || echo "0")
        changes=$((changes + count))
        if [ "$DRY_RUN" = true ]; then
            echo "  ${YELLOW}Найдено: .qwen/.qwen/ ($count раз)${NC}" >&2
        fi
    fi
    
    # Проверка на `.specify/` (в начале пути)
    if grep -q '\.specify/' "$file" 2>/dev/null; then
        count=$(grep -c '\.specify/' "$file" 2>/dev/null || echo "0")
        changes=$((changes + count))
        if [ "$DRY_RUN" = true ]; then
            echo "  ${YELLOW}Найдено: .specify/ ($count раз)${NC}" >&2
        fi
    fi
    
    # Проверка на `specs/` (в начале пути, не .qwen/specify/specs/)
    # Исключаем уже корректные пути
    if grep -E '[^a-zA-Z]specs/' "$file" 2>/dev/null | grep -v '\.qwen/specify/specs/' > /dev/null 2>&1; then
        count=$(grep -E '[^a-zA-Z]specs/' "$file" 2>/dev/null | grep -v '\.qwen/specify/specs/' | wc -l || echo "0")
        changes=$((changes + count))
        if [ "$DRY_RUN" = true ]; then
            echo "  ${YELLOW}Найдено: specs/ ($count раз)${NC}" >&2
        fi
    fi
    
    # Проверка на `.qwen/specify/specs/` (должно быть specs/)
    if grep -q '\.qwen/specify/specs/' "$file" 2>/dev/null; then
        count=$(grep -c '\.qwen/specify/specs/' "$file" 2>/dev/null || echo "0")
        changes=$((changes + count))
        if [ "$DRY_RUN" = true ]; then
            echo "  ${YELLOW}Найдено: .qwen/specify/specs/ ($count раз)${NC}" >&2
        fi
    fi
    
    # Возвращаем только число
    echo $changes
}

# Функция исправления файла
fix_file() {
    local file="$1"
    local temp_file=$(mktemp)
    
    cp "$file" "$temp_file"
    
    # Замена `.qwen/.qwen/` → `.qwen/`
    sed -i 's|\.qwen/\.qwen/|\.qwen/|g' "$temp_file"
    
    # Замена `.specify/` → `.qwen/specify/`
    sed -i 's|\.specify/|.qwen/specify/|g' "$temp_file"
    
    # Замена `.qwen/specify/specs/` → `specs/` (для краткости)
    sed -i 's|\.qwen/specify/specs/|specs/|g' "$temp_file"
    
    # Проверка изменений
    if ! diff -q "$file" "$temp_file" > /dev/null 2>&1; then
        mv "$temp_file" "$file"
        return 0
    else
        rm "$temp_file"
        return 1
    fi
}

# Основная функция
main() {
    # Парсинг аргументов
    while [[ $# -gt 0 ]]; do
        case $1 in
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --fix)
                FIX=true
                shift
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            *)
                log_error "Неизвестный аргумент: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    # Проверка режимов
    if [ "$DRY_RUN" = false ] && [ "$FIX" = false ]; then
        log_error "Укажите --dry-run или --fix"
        show_help
        exit 1
    fi
    
    if [ "$DRY_RUN" = true ] && [ "$FIX" = true ]; then
        log_error "Нельзя указать одновременно --dry-run и --fix"
        exit 1
    fi
    
    log_info "Проект: ${PROJECT_ROOT}"
    
    if [ "$DRY_RUN" = true ]; then
        log_info "Режим: Предварительный просмотр"
    elif [ "$FIX" = true ]; then
        log_info "Режим: Исправление файлов"
        mkdir -p "${PROJECT_ROOT}/.qwen/reports/validation"
    fi
    
    echo ""
    
    # Поиск и обработка файлов
    local files=$(find_md_files)
    
    for file in $files; do
        local changes=$(check_file "$file")
        
        if [ "$changes" -gt 0 ]; then
            TOTAL_FILES=$((TOTAL_FILES + 1))
            TOTAL_CHANGES=$((TOTAL_CHANGES + changes))
            
            if [ "$DRY_RUN" = true ]; then
                echo -e "${YELLOW}Файл: ${file}${NC}"
                echo "  Изменений: $changes"
            elif [ "$FIX" = true ]; then
                if fix_file "$file"; then
                    MODIFIED_FILES=$((MODIFIED_FILES + 1))
                    log_success "Исправлен: $file"
                fi
            fi
        fi
    done
    
    # Вывод результатов
    echo ""
    echo "=========================================="
    echo "           Результаты проверки           "
    echo "=========================================="
    
    if [ "$DRY_RUN" = true ]; then
        echo "Найдено файлов с проблемами: ${TOTAL_FILES}"
        echo "Всего замен требуется: ${TOTAL_CHANGES}"
        echo ""
        if [ "$TOTAL_FILES" -gt 0 ]; then
            log_warning "Запустите с --fix для применения изменений"
        else
            log_success "Проблем не найдено"
        fi
    elif [ "$FIX" = true ]; then
        echo "Исправлено файлов: ${MODIFIED_FILES}"
        echo "Всего замен выполнено: ${TOTAL_CHANGES}"
        echo ""
        if [ "$MODIFIED_FILES" -gt 0 ]; then
            log_success "Изменения применены"
        else
            log_info "Изменений не потребовалось"
        fi
    fi
    
    echo ""
}

# Запуск
main "$@"
