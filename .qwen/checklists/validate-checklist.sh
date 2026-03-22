#!/bin/bash
#
# Validate Checklist - Автоматическая валидация по чек-листам
# Назначение: Проверка пунктов чек-листа, вычисление % выполнения, рекомендации
# Версия: 1.0.0
#

set -euo pipefail

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

# Конфигурация
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
CHECKLISTS_DIR="$SCRIPT_DIR"
REPORTS_DIR="$SCRIPT_DIR/reports"
TIMESTAMP=$(date +%Y-%m-%d_%H-%M-%S)
DATE=$(date +%Y-%m-%d)

# Флаги
VERBOSE=false
QUIET=false
AUTO_FIX=false
OUTPUT_DIR="$REPORTS_DIR"
CHECKLIST_NAME=""
CHECK_ALL=false

# Функция для логирования
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

log_header() {
    echo -e "${WHITE}========================================${NC}"
    echo -e "${WHITE}  $1${NC}"
    echo -e "${WHITE}========================================${NC}"
}

log_step() {
    echo -e "${CYAN}→${NC} $1"
}

# Показать помощь
show_help() {
    cat << EOF
${WHITE}Validate Checklist v1.0.0${NC}

Автоматическая валидация по чек-листам

${WHITE}Использование:${NC}
  $(basename "$0") [OPTIONS]

${WHITE}Опции:${NC}
  -h, --help              Показать эту справку
  -v, --verbose           Подробный вывод
  -q, --quiet             Тихий режим
  -o, --output DIR        Директория для вывода
  -n, --name NAME         Имя чек-листа для проверки
  -a, --all               Проверить все чек-листы
  --auto-fix              Автоматическое исправление проблем

${WHITE}Доступные чек-листы:${NC}
  - Pre-Flight (10 пунктов)
  - Pre-Commit (7 пунктов)
  - Pre-Merge (8 пунктов)
  - TDD (6 пунктов)
  - Agent Assignment (6 пунктов)
  - Specification (9 пунктов)
  - Phase 0 (7 пунктов)
  - Initialization (9 пунктов)
  - Release (12 пунктов)
  - Health Check (4 пункта)

${WHITE}Примеры:${NC}
  $(basename "$0") --all                          # Проверка всех чек-листов
  $(basename "$0") --name "Pre-Flight"            # Проверка конкретного
  $(basename "$0") --name "Pre-Commit" --auto-fix # С авто-исправлением

${WHITE}Выход:${NC}
  - STDOUT с результатами проверки
  - JSON отчет
  - Markdown отчет
EOF
}

# Проверка зависимостей
check_dependencies() {
    local missing=()

    if ! command -v jq &> /dev/null; then
        missing+=("jq")
    fi

    if [ ${#missing[@]} -gt 0 ]; then
        log_error "Отсутствуют зависимости: ${missing[*]}"
        return 1
    fi

    return 0
}

# Получить список доступных чек-листов
get_available_checklists() {
    local checklists=()
    for file in "$CHECKLISTS_DIR"/*-checklist.md; do
        if [ -f "$file" ]; then
            local name=$(basename "$file" -checklist.md | sed 's/-/ /g' | sed 's/\b\(.\)/\u\1/g')
            checklists+=("$name")
        fi
    done
    echo "${checklists[@]}"
}

# Преобразование имени чек-листа в имя файла
checklist_name_to_file() {
    local name="$1"
    local file_name=$(echo "$name" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')
    echo "$CHECKLISTS_DIR/${file_name}-checklist.md"
}

# Парсинг чек-листа
parse_checklist() {
    local file="$1"
    
    if [ ! -f "$file" ]; then
        return 1
    fi
    
    # Извлечение пунктов чек-листа
    local items=()
    local in_checklist=false
    
    while IFS= read -r line; do
        # Поиск начала чек-листа
        if [[ "$line" == *"- [ ]"* ]] || [[ "$line" == *"- [x]"* ]] || [[ "$line" == *"- [X]"* ]]; then
            in_checklist=true
            items+=("$line")
        elif [[ "$line" == "##"* ]] && [ "$in_checklist" = true ]; then
            break
        elif [ "$in_checklist" = true ] && [[ -z "$line" || "$line" == "---"* ]]; then
            break
        fi
    done < "$file"
    
    printf '%s\n' "${items[@]}"
}

# Проверка пункта чек-листа
check_item() {
    local item="$1"
    local status="pending"
    local description=""
    local auto_fixable=false
    local auto_fix_command=""
    
    # Извлечение описания
    description=$(echo "$item" | sed 's/.*\*\*\([0-9.]*\)\*\*//' | sed 's/^- \[.\] //' | xargs)
    
    # Определение статуса из markdown
    if [[ "$item" == *"- [x]"* ]] || [[ "$item" == *"- [X]"* ]]; then
        status="completed"
    else
        status="pending"
    fi
    
    # Автоматическая проверка для известных пунктов
    case "$description" in
        *"Git репозиторий инициализирован"*|*".git существует"*)
            if [ -d "$PROJECT_ROOT/.git" ]; then
                status="passed"
            else
                status="failed"
            fi
            auto_fixable=false
            ;;
        *"Ветка develop существует"*)
            if git -C "$PROJECT_ROOT" rev-parse --verify develop &>/dev/null; then
                status="passed"
            else
                status="failed"
            fi
            auto_fixable=true
            auto_fix_command="git -C \"$PROJECT_ROOT\" checkout -b develop"
            ;;
        *".gitignore существует"*)
            if [ -f "$PROJECT_ROOT/.gitignore" ]; then
                status="passed"
            else
                status="failed"
            fi
            auto_fixable=true
            auto_fix_command="touch \"$PROJECT_ROOT/.gitignore\""
            ;;
        *"README.md существует"*)
            if [ -f "$PROJECT_ROOT/README.md" ]; then
                status="passed"
            else
                status="failed"
            fi
            auto_fixable=true
            auto_fix_command="echo '# Project' > \"$PROJECT_ROOT/README.md\""
            ;;
        *".version существует"*)
            if [ -f "$PROJECT_ROOT/.version" ]; then
                status="passed"
            else
                status="failed"
            fi
            auto_fixable=true
            auto_fix_command="echo '0.1.0' > \"$PROJECT_ROOT/.version\""
            ;;
        *"package.json существует"*)
            if [ -f "$PROJECT_ROOT/package.json" ]; then
                status="passed"
            else
                status="failed"
            fi
            auto_fixable=false
            ;;
        *".qwen/ директория существует"*)
            if [ -d "$PROJECT_ROOT/.qwen" ]; then
                status="passed"
            else
                status="failed"
            fi
            auto_fixable=true
            auto_fix_command="mkdir -p \"$PROJECT_ROOT/.qwen\""
            ;;
        *".qwen/agents/ директория существует"*)
            if [ -d "$PROJECT_ROOT/.qwen/agents" ]; then
                status="passed"
            else
                status="failed"
            fi
            auto_fixable=true
            auto_fix_command="mkdir -p \"$PROJECT_ROOT/.qwen/agents\""
            ;;
        *".qwen/mcp.json существует"*)
            if [ -f "$PROJECT_ROOT/.qwen/mcp.json" ]; then
                status="passed"
            else
                status="failed"
            fi
            auto_fixable=false
            ;;
        *"constitution.md существует"*)
            if [ -f "$PROJECT_ROOT/constitution.md" ]; then
                status="passed"
            else
                status="failed"
            fi
            auto_fixable=true
            auto_fix_command="touch \"$PROJECT_ROOT/constitution.md\""
            ;;
        *"CHANGELOG.md создан"*)
            if [ -f "$PROJECT_ROOT/CHANGELOG.md" ]; then
                status="passed"
            else
                status="failed"
            fi
            auto_fixable=true
            auto_fix_command="echo '# Changelog' > \"$PROJECT_ROOT/CHANGELOG.md\""
            ;;
        *"LICENSE"*|*"LICENSE выбран"*)
            if [ -f "$PROJECT_ROOT/LICENSE" ] || [ -f "$PROJECT_ROOT/LICENSE.md" ]; then
                status="passed"
            else
                status="failed"
            fi
            auto_fixable=false
            ;;
        *"Изменения протестированы"*|*"Тесты проходят"*)
            # Пропускаем - требует ручного подтверждения
            status="manual"
            ;;
        *"Код проходит линтинг"*|*"Линтинг"*)
            status="manual"
            ;;
        *"Форматирование применено"*)
            status="manual"
            ;;
        *"Сообщение коммита следует"*)
            status="manual"
            ;;
        *"Pre-commit хуки"*)
            if [ -f "$PROJECT_ROOT/.git/hooks/pre-commit" ]; then
                status="passed"
            else
                status="failed"
            fi
            auto_fixable=false
            ;;
        *"Все тесты проходят"*)
            status="manual"
            ;;
        *"Code review выполнен"*)
            status="manual"
            ;;
        *"CI/CD пайплайн"*)
            status="manual"
            ;;
        *"Ветка обновлена"*)
            status="manual"
            ;;
        *"Конфликты слияния"*)
            status="manual"
            ;;
        *"CHANGELOG обновлен"*)
            status="manual"
            ;;
        *"Документация обновлена"*)
            status="manual"
            ;;
        *"Метрики качества"*)
            status="manual"
            ;;
        *"Тест написан до"*)
            status="manual"
            ;;
        *"Тест падает"*)
            status="manual"
            ;;
        *"Минимальная реализация"*)
            status="manual"
            ;;
        *"Тест проходит"*)
            status="manual"
            ;;
        *"Рефакторинг кода"*)
            status="manual"
            ;;
        *"Агент имеет соответствующую"*)
            status="manual"
            ;;
        *"Агент доступен"*)
            status="manual"
            ;;
        *"Агент имеет необходимые"*)
            status="manual"
            ;;
        *"Приоритет агента"*)
            status="manual"
            ;;
        *"nextAgent определен"*)
            status="manual"
            ;;
        *"Fallback агент"*)
            status="manual"
            ;;
        *"spec.md существует"*)
            # Проверка наличия spec.md в specs/
            if ls "$PROJECT_ROOT/specs"/*/spec.md &>/dev/null 2>&1; then
                status="passed"
            else
                status="failed"
            fi
            auto_fixable=false
            ;;
        *"Требования четко"*)
            status="manual"
            ;;
        *"Требования тестируемы"*)
            status="manual"
            ;;
        *"Критерии приемки"*)
            status="manual"
            ;;
        *"Границы задачи"*)
            status="manual"
            ;;
        *"Зависимости документированы"*)
            status="manual"
            ;;
        *"Риски идентифицированы"*)
            status="manual"
            ;;
        *"Сроки реалистичны"*)
            status="manual"
            ;;
        *"Стейкхолдеры согласовали"*)
            status="manual"
            ;;
        *"Задача проанализирована"*)
            status="manual"
            ;;
        *"Требования извлечены"*)
            status="manual"
            ;;
        *"Подзадачи идентифицированы"*)
            status="manual"
            ;;
        *"Исполнители назначены"*)
            status="manual"
            ;;
        *"План выполнения создан"*)
            status="manual"
            ;;
        *"Приоритеты установлены"*)
            status="manual"
            ;;
        *"План валидирован"*)
            status="manual"
            ;;
        *"Все PR закрыты"*)
            status="manual"
            ;;
        *"Версия обновлена"*)
            status="manual"
            ;;
        *"Тег создан"*)
            status="manual"
            ;;
        *"Релиз задокументирован"*)
            status="manual"
            ;;
        *"Зависимости обновлены"*)
            status="manual"
            ;;
        *"Безопасность проверена"*)
            status="manual"
            ;;
        *"Документация актуализирована"*)
            status="manual"
            ;;
        *"Артефакты собраны"*)
            status="manual"
            ;;
        *"Уведомления отправлены"*)
            status="manual"
            ;;
        *"Post-release проверка"*)
            status="manual"
            ;;
        *"Git workflow соблюдается"*)
            status="manual"
            ;;
        *"Качество кода на уровне"*)
            status="manual"
            ;;
        *"Тесты покрывают"*)
            status="manual"
            ;;
        *"Нет критических уязвимостей"*)
            status="manual"
            ;;
        *)
            # По умолчанию - manual проверка
            status="manual"
            ;;
    esac
    
    echo "$status|$description|$auto_fixable|$auto_fix_command"
}

# Валидация чек-листа
validate_checklist() {
    local name="$1"
    local file=$(checklist_name_to_file "$name")
    
    if [ ! -f "$file" ]; then
        log_error "Чек-лист не найден: $name"
        return 1
    fi
    
    log_step "Валидация чек-листа: $name"
    
    declare -a RESULTS=()
    local total=0
    local passed=0
    local failed=0
    local manual=0
    local pending=0
    
    # Чтение и проверка каждого пункта
    while IFS= read -r item; do
        if [ -n "$item" ]; then
            local result=$(check_item "$item")
            RESULTS+=("$result")
            
            local status=$(echo "$result" | cut -d'|' -f1)
            total=$((total + 1))
            
            case "$status" in
                passed) passed=$((passed + 1)) ;;
                failed) failed=$((failed + 1)) ;;
                manual) manual=$((manual + 1)) ;;
                pending) pending=$((pending + 1)) ;;
            esac
        fi
    done < <(parse_checklist "$file")
    
    # Расчет процентов
    local percentage=0
    if [ "$total" -gt 0 ]; then
        percentage=$((passed * 100 / total))
    fi
    
    # Вывод результатов
    echo ""
    echo -e "${WHITE}$name: $passed/$total (${percentage}%)${NC}"
    echo ""
    
    for result in "${RESULTS[@]}"; do
        local status=$(echo "$result" | cut -d'|' -f1)
        local description=$(echo "$result" | cut -d'|' -f2)
        local auto_fixable=$(echo "$result" | cut -d'|' -f3)
        local auto_fix_command=$(echo "$result" | cut -d'|' -f4)
        
        case "$status" in
            passed)
                echo -e "  ${GREEN}✅${NC} $description"
                ;;
            failed)
                echo -e "  ${RED}❌${NC} $description - НЕ ВЫПОЛНЕНО"
                if [ "$auto_fixable" = "true" ] && [ "$AUTO_FIX" = true ]; then
                    log_step "Авто-исправление: $description"
                    eval "$auto_fix_command" 2>/dev/null && log_success "Исправлено" || log_warning "Не удалось исправить"
                fi
                ;;
            manual)
                echo -e "  ${YELLOW}⚠️${NC} $description - ТРЕБУЕТ ПРОВЕРКИ"
                ;;
            pending)
                echo -e "  ${BLUE}⏳${NC} $description"
                ;;
        esac
    done
    
    echo ""
    
    # Рекомендации
    if [ "$failed" -gt 0 ] || [ "$manual" -gt 0 ]; then
        echo -e "${WHITE}Recommendations:${NC}"
        local rec_num=1
        
        for result in "${RESULTS[@]}"; do
            local status=$(echo "$result" | cut -d'|' -f1)
            local description=$(echo "$result" | cut -d'|' -f2)
            local auto_fixable=$(echo "$result" | cut -d'|' -f3)
            local auto_fix_command=$(echo "$result" | cut -d'|' -f4)
            
            if [ "$status" = "failed" ]; then
                if [ "$auto_fixable" = "true" ]; then
                    echo "  $rec_num. $description - доступно авто-исправление"
                else
                    echo "  $rec_num. $description - требует ручного исправления"
                fi
                rec_num=$((rec_num + 1))
            fi
        done
        
        for result in "${RESULTS[@]}"; do
            local status=$(echo "$result" | cut -d'|' -f1)
            local description=$(echo "$result" | cut -d'|' -f2)
            
            if [ "$status" = "manual" ]; then
                echo "  $rec_num. $description - проверьте вручную"
                rec_num=$((rec_num + 1))
            fi
        done
        echo ""
    fi
    
    # Возврат кода статуса
    if [ "$failed" -gt 0 ]; then
        return 1
    fi
    return 0
}

# Генерация JSON отчета
generate_json_report() {
    local name="$1"
    local passed="$2"
    local total="$3"
    local percentage="$4"
    
    local json_file="$OUTPUT_DIR/checklist-validation-$TIMESTAMP.json"
    
    cat > "$json_file" << EOF
{
  "timestamp": "$TIMESTAMP",
  "date": "$DATE",
  "checklist": "$name",
  "result": {
    "passed": $passed,
    "total": $total,
    "percentage": $percentage,
    "status": "$([ "$percentage" -ge 90 ] && echo "passed" || ([ "$percentage" -ge 70 ] && echo "warning" || echo "failed"))"
  }
}
EOF
    
    log_success "JSON отчет: $json_file"
}

# Генерация Markdown отчета
generate_markdown_report() {
    local name="$1"
    local passed="$2"
    local total="$3"
    local percentage="$4"
    
    local md_file="$OUTPUT_DIR/checklist-validation-$TIMESTAMP.md"
    
    cat > "$md_file" << EOF
# Checklist Validation Report

**Чек-лист**: $name  
**Дата**: $DATE  
**Время**: $TIMESTAMP

---

## Результат

| Метрика | Значение |
|---------|----------|
| Выполнено | $passed из $total |
| Процент | ${percentage}% |
| Статус | $([ "$percentage" -ge 90 ] && echo "✅ Passed" || ([ "$percentage" -ge 70 ] && echo "⚠️ Warning" || echo "❌ Failed")) |

---

## Детали

См. вывод в STDOUT для подробной информации по каждому пункту.

---

*Report сгенерирован Qwen Orchestrator Kit - Checklist Validation v1.0.0*
EOF
    
    log_success "Markdown отчет: $md_file"
}

# Основная функция
main() {
    # Парсинг аргументов
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -q|--quiet)
                QUIET=true
                shift
                ;;
            -o|--output)
                OUTPUT_DIR="$2"
                shift 2
                ;;
            -n|--name)
                CHECKLIST_NAME="$2"
                shift 2
                ;;
            -a|--all)
                CHECK_ALL=true
                shift
                ;;
            --auto-fix)
                AUTO_FIX=true
                shift
                ;;
            *)
                log_error "Неизвестная опция: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    # Создание директории вывода
    mkdir -p "$OUTPUT_DIR"
    
    if [ "$QUIET" = false ]; then
        echo ""
        log_header "Validate Checklist v1.0.0"
        echo ""
    fi
    
    # Проверки
    if ! check_dependencies; then
        exit 1
    fi
    
    # Проверка аргументов
    if [ -z "$CHECKLIST_NAME" ] && [ "$CHECK_ALL" = false ]; then
        log_error "Укажите --name или --all"
        show_help
        exit 1
    fi
    
    local exit_code=0
    
    if [ "$CHECK_ALL" = true ]; then
        # Проверка всех чек-листов
        for file in "$CHECKLISTS_DIR"/*-checklist.md; do
            if [ -f "$file" ]; then
                local name=$(basename "$file" -checklist.md | sed 's/-/ /g' | sed 's/\b\(.\)/\u\1/g')
                if ! validate_checklist "$name"; then
                    exit_code=1
                fi
            fi
        done
    else
        # Проверка конкретного чек-листа
        if ! validate_checklist "$CHECKLIST_NAME"; then
            exit_code=1
        fi
    fi
    
    if [ "$QUIET" = false ]; then
        log_success "Валидация завершена"
        echo ""
    fi
    
    exit $exit_code
}

main "$@"
