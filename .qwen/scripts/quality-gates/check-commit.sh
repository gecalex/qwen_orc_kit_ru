#!/bin/bash
# =============================================================================
# Скрипт: .qwen/scripts/quality-gates/check-commit.sh
# Назначение: Quality Gate 3 - Pre-Commit проверка перед коммитом
# =============================================================================
# Блокирующая: true (останавливает выполнение при ошибках валидации)
#
# Проверки:
# - Pre-commit валидация синтаксиса
# - Проверка git workflow
# - Валидация сообщения коммита (Conventional Commits)
#
# Использование:
#   .qwen/scripts/quality-gates/check-commit.sh
#
# Выход:
#   0 - Все проверки пройдены
#   1 - Проверка не пройдена (блокирующая ошибка)
# =============================================================================

set -o pipefail

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Счетчики ошибок
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0

# =============================================================================
# Функции
# =============================================================================

print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  Quality Gate 3: Pre-Commit${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
}

print_check() {
    local name="$1"
    local status="$2"  # "pass", "fail", "warn"
    
    ((TOTAL_CHECKS++))
    
    case $status in
        pass)
            echo -e "${GREEN}✓${NC} $name"
            ((PASSED_CHECKS++))
            ;;
        fail)
            echo -e "${RED}✗${NC} $name"
            ((FAILED_CHECKS++))
            ;;
        warn)
            echo -e "${YELLOW}⚠${NC} $name"
            ((PASSED_CHECKS++))
            ;;
    esac
}

print_section() {
    echo ""
    echo -e "${BLUE}=== $1 ===${NC}"
}

# Проверка 1: Pre-commit валидация синтаксиса
check_syntax_validation() {
    print_section "Проверка синтаксиса файлов"
    
    local script_dir="$(dirname "$(readlink -f "$0")")"
    local validation_script="$script_dir/pre-commit-validation.sh"
    
    if [ ! -f "$validation_script" ]; then
        print_check "Скрипт валидации не найден" "fail"
        return 1
    fi
    
    # Запускаем валидацию
    if "$validation_script" --verbose; then
        print_check "Валидация синтаксиса" "pass"
        return 0
    else
        print_check "Валидация синтаксиса" "fail"
        return 1
    fi
}

# Проверка 2: Git workflow
check_git_workflow() {
    print_section "Проверка Git workflow"
    
    local script_dir="$(dirname "$(readlink -f "$0")")"
    local workflow_script="$script_dir/../git/check-workflow.sh"
    
    if [ ! -f "$workflow_script" ]; then
        print_check "Скрипт git workflow не найден" "warn"
        return 0
    fi
    
    # Запускаем проверку workflow
    if "$workflow_script" > /dev/null 2>&1; then
        print_check "Git workflow" "pass"
        return 0
    else
        # Получаем детали ошибки
        local output=$("$workflow_script" 2>&1)
        local exit_code=$?
        
        if [ $exit_code -eq 2 ]; then
            print_check "Git workflow (критические ошибки)" "fail"
            echo "  Детали: $output"
            return 1
        else
            print_check "Git workflow (предупреждения)" "warn"
            echo "  Детали: $output"
            return 0
        fi
    fi
}

# Проверка 3: Валидация сообщения коммита (Conventional Commits)
check_commit_message() {
    print_section "Проверка формата сообщения коммита"
    
    # Проверяем наличие подготовленных файлов
    local staged_files=$(git diff --cached --name-only 2>/dev/null)
    
    if [ -z "$staged_files" ]; then
        print_check "Нет staged файлов для коммита" "warn"
        return 0
    fi
    
    # Проверяем наличие prepare-commit-msg хука или сообщения
    local commit_msg_file=".git/COMMIT_EDITMSG"
    
    if [ -f "$commit_msg_file" ]; then
        local commit_msg=$(head -1 "$commit_msg_file")
        
        # Паттерн Conventional Commits: type(scope): description
        # Типы: feat, fix, docs, style, refactor, test, chore, perf, ci, build, revert
        local pattern="^(feat|fix|docs|style|refactor|test|chore|perf|ci|build|revert)(\([a-zA-Z0-9_-]+\))?: .+"
        
        if [[ $commit_msg =~ $pattern ]]; then
            print_check "Формат сообщения (Conventional Commits)" "pass"
            echo "  Сообщение: $commit_msg"
            return 0
        else
            print_check "Формат сообщения (Conventional Commits)" "fail"
            echo "  Сообщение: $commit_msg"
            echo "  Ожидается: type(scope): description"
            echo "  Примеры: feat(auth): Add JWT support, fix(api): Fix null pointer"
            return 1
        fi
    else
        print_check "Сообщение коммита (не найдено)" "warn"
        echo "  Сообщение будет проверено при коммите"
        return 0
    fi
}

# Проверка 4: Наличие .gitignore
check_gitignore() {
    print_section "Проверка .gitignore"
    
    if [ -f ".gitignore" ]; then
        print_check "Файл .gitignore существует" "pass"
        
        # Проверяем наличие стандартных записей
        local has_node_modules=$(grep -c "node_modules" .gitignore 2>/dev/null || echo "0")
        local has_env=$(grep -c "\.env" .gitignore 2>/dev/null || echo "0")
        local has_cache=$(grep -c "__pycache__" .gitignore 2>/dev/null || echo "0")
        
        if [ "$has_node_modules" -gt 0 ]; then
            print_check ".gitignore: node_modules" "pass"
        else
            print_check ".gitignore: node_modules" "warn"
        fi
        
        if [ "$has_env" -gt 0 ]; then
            print_check ".gitignore: .env файлы" "pass"
        else
            print_check ".gitignore: .env файлы" "warn"
        fi
        
        if [ "$has_cache" -gt 0 ]; then
            print_check ".gitignore: __pycache__" "pass"
        else
            print_check ".gitignore: __pycache__" "warn"
        fi
        
        return 0
    else
        print_check "Файл .gitignore не найден" "fail"
        return 1
    fi
}

# Проверка 5: Проверка незакоммиченных секретов (базовая)
check_secrets() {
    print_section "Проверка на наличие секретов"
    
    local staged_files=$(git diff --cached --name-only 2>/dev/null)
    
    if [ -z "$staged_files" ]; then
        print_check "Нет staged файлов для проверки секретов" "warn"
        return 0
    fi
    
    local found_secrets=false
    
    # Проверяем файлы на наличие паттернов секретов
    while IFS= read -r file; do
        [ -z "$file" ] && continue
        [ ! -f "$file" ] && continue
        
        # Пропускаем тестовые файлы и примеры
        if [[ "$file" == *".example"* ]] || [[ "$file" == *".sample"* ]] || [[ "$file" == *"test"* ]]; then
            continue
        fi
        
        # Проверяем на наличие паттернов API ключей
        if grep -qE "(api[_-]?key|apikey|secret[_-]?key|password|passwd|pwd)\s*[=:]\s*['\"][^'\"]{8,}['\"]" "$file" 2>/dev/null; then
            print_warning "Возможный секрет в файле: $file"
            found_secrets=true
        fi
        
        # Проверяем на наличие токенов
        if grep -qE "(token|bearer|authorization)\s*[=:]\s*['\"][^'\"]{20,}['\"]" "$file" 2>/dev/null; then
            print_warning "Возможный токен в файле: $file"
            found_secrets=true
        fi
    done <<< "$staged_files"
    
    if [ "$found_secrets" = true ]; then
        print_check "Проверка секретов" "warn"
        echo "  ⚠️  Обнаружены потенциальные секреты. Проверьте файлы перед коммитом."
        return 0
    else
        print_check "Проверка секретов" "pass"
        return 0
    fi
}

# Вывод итогов
print_summary() {
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  Итоги Quality Gate 3${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
    echo "Всего проверок: $TOTAL_CHECKS"
    echo -e "Пройдено: ${GREEN}$PASSED_CHECKS${NC}"
    echo -e "Не пройдено: ${RED}$FAILED_CHECKS${NC}"
    echo ""
    
    if [ $FAILED_CHECKS -eq 0 ]; then
        echo -e "${GREEN}✅ Quality Gate 3 пройден${NC}"
        echo ""
        echo "Можно выполнять коммит:"
        echo "  git commit -m \"type(scope): description\""
        return 0
    else
        echo -e "${RED}❌ Quality Gate 3 НЕ пройден${NC}"
        echo ""
        echo "Устраните ошибки перед коммитом:"
        echo "  1. Исправьте ошибки синтаксиса"
        echo "  2. Проверьте git workflow"
        echo "  3. Убедитесь в правильности сообщения коммита"
        return 1
    fi
}

# Показать справку
show_help() {
    echo "Quality Gate 3: Pre-Commit проверка"
    echo ""
    echo "Использование:"
    echo "  $0"
    echo ""
    echo "Проверки:"
    echo "  1. Валидация синтаксиса файлов (Python, Bash, Markdown, JSON, YAML)"
    echo "  2. Проверка Git workflow"
    echo "  3. Валидация сообщения коммита (Conventional Commits)"
    echo "  4. Наличие и настройка .gitignore"
    echo "  5. Базовая проверка на наличие секретов"
    echo ""
    echo "Выходные коды:"
    echo "  0 - Все проверки пройдены"
    echo "  1 - Проверка не пройдена (блокирующая ошибка)"
    echo ""
}

# =============================================================================
# Основная логика
# =============================================================================

main() {
    # Парсинг аргументов
    if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
        show_help
        exit 0
    fi
    
    print_header
    
    # Проверка наличия git
    if ! command -v git &> /dev/null; then
        echo -e "${RED}✗${NC} Git не найден. Установите git для работы скрипта."
        exit 1
    fi
    
    # Проверка нахождения в git репозитории
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        echo -e "${RED}✗${NC} Текущая директория не является git репозиторием."
        exit 1
    fi
    
    # Запуск проверок
    local failed=false
    
    check_syntax_validation || failed=true
    check_git_workflow || failed=true
    check_commit_message || failed=true
    check_gitignore || failed=true
    check_secrets || failed=true
    
    # Вывод итогов
    print_summary
    local result=$?
    
    if [ "$failed" = true ] || [ $result -ne 0 ]; then
        exit 1
    fi
    
    exit 0
}

# Запуск основной функции
main "$@"
