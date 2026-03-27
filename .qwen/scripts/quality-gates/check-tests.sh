#!/bin/bash

# =============================================================================
# check-tests.sh - Quality Gate для тестов
# =============================================================================
# Назначение: Проверка тестов на наличие failed, errors и warnings
# 
# Функционал:
#   - Запустить тесты
#   - Подсчитать failed, errors, warnings
#   - Проверить пороги
#   - Вернуть статус
#
# Использование:
#   .qwen/scripts/quality-gates/check-tests.sh [backend_dir]
# =============================================================================

set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Переменные
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR/../.."
BACKEND_DIR="${1:-$PROJECT_ROOT/backend}"

# Пороги (универсальные, настраиваемые)
MAX_WARNINGS=${MAX_WARNINGS:-50}
MAX_FAILED=${MAX_FAILED:-0}
MAX_ERRORS=${MAX_ERRORS:-0}

# Функция вывода помощи
show_help() {
    echo -e "${BLUE}check-tests.sh - Quality Gate для тестов${NC}"
    echo ""
    echo "Использование:"
    echo "  $0 [backend_dir]"
    echo ""
    echo "Пороги (по умолчанию):"
    echo "  MAX_WARNINGS=$MAX_WARNINGS"
    echo "  MAX_FAILED=$MAX_FAILED"
    echo "  MAX_ERRORS=$MAX_ERRORS"
    echo ""
    echo "Примеры:"
    echo "  $0"
    echo "  $0 backend"
    echo "  MAX_WARNINGS=100 $0"
}

# Функция логирования
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Проверка наличия pytest
check_pytest() {
    if ! command -v pytest &> /dev/null; then
        log_error "pytest не установлен"
        exit 1
    fi
    log_success "pytest найден"
}

# Проверка наличия тестов
check_tests_exist() {
    if [ ! -d "$BACKEND_DIR/tests" ]; then
        log_error "Директория с тестами не найдена: $BACKEND_DIR/tests"
        exit 1
    fi
    
    local test_count=$(find "$BACKEND_DIR/tests" -name "test_*.py" | wc -l)
    if [ "$test_count" -eq 0 ]; then
        log_error "Тесты не найдены в $BACKEND_DIR/tests"
        exit 1
    fi
    
    log_success "Найдено тестов: $test_count"
}

# Запустить тесты
run_tests() {
    log_info "Запуск тестов..."
    
    cd "$BACKEND_DIR"
    
    # Запустить тесты и сохранить вывод
    local output=$(pytest tests/ -v --tb=no 2>&1 | tee /tmp/pytest-output.txt)
    
    # Сохранить вывод
    echo "$output" > /tmp/pytest-output.txt
    
    log_success "Тесты завершены"
}

# Подсчитать failed, errors, warnings
count_results() {
    log_info "Подсчёт результатов..."
    
    # Подсчитать failed
    FAILED=$(grep -c "FAILED" /tmp/pytest-output.txt || echo "0")
    
    # Подсчитать errors
    ERRORS=$(grep -c "ERROR" /tmp/pytest-output.txt || echo "0")
    
    # Подсчитать warnings
    WARNINGS=$(grep "warnings summary" /tmp/pytest-output.txt | tail -1 | grep -oE "[0-9]+" | head -1 || echo "0")
    
    # Если warnings не найдены, попробовать другой паттерн
    if [ "$WARNINGS" = "0" ] || [ -z "$WARNINGS" ]; then
        WARNINGS=$(grep -c "DeprecationWarning\|UserWarning" /tmp/pytest-output.txt || echo "0")
    fi
    
    echo "  Failed: $FAILED"
    echo "  Errors: $ERRORS"
    echo "  Warnings: $WARNINGS"
}

# Проверить пороги
check_thresholds() {
    local failed=false
    
    # Проверить failed
    if [ "$FAILED" -gt "$MAX_FAILED" ]; then
        log_error "Превышено количество failed: $FAILED > $MAX_FAILED"
        failed=true
    else
        log_success "Failed в норме: $FAILED <= $MAX_FAILED"
    fi
    
    # Проверить errors
    if [ "$ERRORS" -gt "$MAX_ERRORS" ]; then
        log_error "Превышено количество errors: $ERRORS > $MAX_ERRORS"
        failed=true
    else
        log_success "Errors в норме: $ERRORS <= $MAX_ERRORS"
    fi
    
    # Проверить warnings
    if [ "$WARNINGS" -gt "$MAX_WARNINGS" ]; then
        log_error "Превышено количество warnings: $WARNINGS > $MAX_WARNINGS"
        failed=true
    else
        log_success "Warnings в норме: $WARNINGS <= $MAX_WARNINGS"
    fi
    
    if [ "$failed" = true ]; then
        return 1
    fi
    
    return 0
}

# Вывод итогов
print_summary() {
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  Quality Gate: Тесты${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
    echo "Пороги:"
    echo "  MAX_FAILED=$MAX_FAILED"
    echo "  MAX_ERRORS=$MAX_ERRORS"
    echo "  MAX_WARNINGS=$MAX_WARNINGS"
    echo ""
    echo "Результаты:"
    echo "  Failed: $FAILED"
    echo "  Errors: $ERRORS"
    echo "  Warnings: $WARNINGS"
    echo ""
}

# Основная функция
main() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  Quality Gate: Тесты${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
    
    # Проверки
    check_pytest
    check_tests_exist
    
    # Запустить тесты
    run_tests
    
    # Подсчитать результаты
    count_results
    
    # Проверить пороги
    print_summary
    
    if check_thresholds; then
        echo -e "${GREEN}✅ Quality Gate пройден${NC}"
        exit 0
    else
        echo -e "${RED}❌ Quality Gate НЕ пройден${NC}"
        echo ""
        echo "Рекомендации:"
        if [ "$FAILED" -gt "$MAX_FAILED" ]; then
            echo "  1. Исправить failed тесты"
        fi
        if [ "$ERRORS" -gt "$MAX_ERRORS" ]; then
            echo "  2. Исправить errors в fixtures"
        fi
        if [ "$WARNINGS" -gt "$MAX_WARNINGS" ]; then
            echo "  3. Добавить filterwarnings в pytest.ini"
        fi
        exit 1
    fi
}

# Запуск
main "$@"
