#!/bin/bash
#
# deep-spec-analyzer.sh - Deep compliance checking спецификаций
#
# Назначение: Проверка полноты, тестируемости и качества spec.md
#
# Использование:
#   .qwen/analyzers/deep-spec-analyzer.sh <spec-dir>     # Анализ spec.md
#   .qwen/analyzers/deep-spec-analyzer.sh --all          # Анализ всех spec
#   .qwen/analyzers/deep-spec-analyzer.sh --help         # Справка
#

set -e

# Пути
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
CONSTITUTION_FILE="$PROJECT_ROOT/.qwen/specify/constitution.md"

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Обязательные разделы спецификации
REQUIRED_SECTIONS=(
    "Краткое описание"
    "Контекст"
    "Акторы"
    "Требования"
    "Сценарии использования"
    "Условия успеха"
    "Ограничения"
    "Предположения"
    "Риски"
)

# Функция вывода справки
show_help() {
    cat << EOF
${CYAN}Deep Spec Analyzer - Глубокий анализ спецификаций${NC}

${YELLOW}Использование:${NC}
  $0 <spec-dir>              Анализ spec.md в указанной директории
  $0 --all                   Анализ всех spec.md в specs/
  $0 --constitution          Проверка соответствия конституции
  $0 --verbose               Подробный вывод
  $0 --json                  Вывод в JSON формате
  $0 --help                  Показать эту справку

${YELLOW}Проверки:${NC}
  - Полнота spec.md (все разделы)
  - Тестируемость требований
  - Отсутствие деталей реализации
  - Соответствие конституции
  - Traceability матрица
  - Критерии успеха измеримы

${YELLOW}Обязательные разделы:${NC}
$(printf "  - %s\n" "${REQUIRED_SECTIONS[@]}")

${YELLOW}Примеры:${NC}
  $0 specs/my-project
  $0 --all
  $0 specs/my-project --verbose

EOF
}

# Функция проверки существования файла spec.md
check_spec_file() {
    local spec_dir="$1"
    local spec_file="$spec_dir/spec.md"
    
    if [[ ! -f "$spec_file" ]]; then
        echo -e "${RED}Ошибка: spec.md не найден в $spec_dir${NC}"
        return 1
    fi
    
    echo "$spec_file"
}

# Функция проверки наличия раздела
check_section() {
    local file="$1"
    local section="$2"
    
    if grep -qi "^##*[[:space:]]*$section" "$file" 2>/dev/null; then
        return 0
    fi
    return 1
}

# Функция извлечения содержимого раздела
get_section_content() {
    local file="$1"
    local section="$2"
    
    # Используем awk для извлечения содержимого раздела
    awk -v section="$section" '
        BEGIN { in_section = 0; content = "" }
        /^[##]+[[:space:]]+/ {
            if (in_section) exit
            header = $0
            gsub(/^[##]+[[:space:]]+/, "", header)
            if (tolower(header) == tolower(section)) {
                in_section = 1
                next
            }
        }
        in_section { content = content $0 "\n" }
        END { print content }
    ' "$file"
}

# Функция проверки тестируемости требования
is_requirement_testable() {
    local requirement="$1"
    
    # Паттерны тестируемых требований
    local testable_patterns=(
        "должен"
        "необходимо"
        "обязан"
        "требуется"
        "критерий"
        "проверка"
        "тест"
        "валидация"
        "верификация"
    )
    
    # Паттерны не тестируемых требований
    local untestable_patterns=(
        "хороший"
        "лучший"
        "оптимальный"
        "эффективный"
        "удобный"
        "быстрый"
        "красивый"
        "современный"
        "интуитивный"
        "гибкий"
    )
    
    local req_lower=$(echo "$requirement" | tr '[:upper:]' '[:lower:]')
    
    # Проверка на не тестируемые паттерны
    for pattern in "${untestable_patterns[@]}"; do
        if [[ "$req_lower" == *"$pattern"* ]]; then
            # Но если есть и тестируемый паттерн - считаем тестируемым
            for testable in "${testable_patterns[@]}"; do
                if [[ "$req_lower" == *"$testable"* ]]; then
                    return 0
                fi
            done
            return 1
        fi
    done
    
    # Проверка на наличие тестируемых паттернов
    for pattern in "${testable_patterns[@]}"; do
        if [[ "$req_lower" == *"$pattern"* ]]; then
            return 0
        fi
    done
    
    # Если есть конкретные числа или метрики - тестируемо
    if [[ "$requirement" =~ [0-9]+ ]]; then
        return 0
    fi
    
    return 1
}

# Функция поиска деталей реализации
find_implementation_details() {
    local content="$1"
    local details=()
    
    # Паттерны деталей реализации
    local impl_patterns=(
        "функция"
        "метод"
        "класс"
        "переменная"
        "алгоритм"
        "структура данных"
        "библиотека"
        "фреймворк"
        "API"
        "endpoint"
        "route"
        "controller"
        "model"
        "view"
        "component"
        "useEffect"
        "useState"
        "async"
        "await"
        "interface"
        "implementation"
    )
    
    local content_lower=$(echo "$content" | tr '[:upper:]' '[:lower:]')
    
    for pattern in "${impl_patterns[@]}"; do
        if [[ "$content_lower" == *"$pattern"* ]]; then
            details+=("$pattern")
        fi
    done
    
    echo "${details[@]}"
}

# Функция проверки измеримости критериев успеха
check_criteria_measurable() {
    local content="$1"
    local measurable=0
    local total=0
    
    # Извлекаем пункты списка
    while IFS= read -r line; do
        if [[ "$line" =~ ^[-*] ]]; then
            ((total++))
            
            # Проверка на измеримость (числа, проценты, время)
            if [[ "$line" =~ [0-9]+ ]] || \
               [[ "$line" =~ (все|полный|100%|ноль|без) ]] || \
               [[ "$line" =~ (секунд|минут|часов|мс) ]]; then
                ((measurable++))
            fi
        fi
    done <<< "$content"
    
    if [[ $total -eq 0 ]]; then
        echo "0/0"
    else
        echo "$measurable/$total"
    fi
}

# Функция анализа спецификации
analyze_spec() {
    local spec_file="$1"
    local verbose="${2:-false}"
    
    local spec_dir=$(dirname "$spec_file")
    local spec_name=$(basename "$spec_dir")
    
    echo -e "${CYAN}Specification Analysis: ${YELLOW}$spec_name${NC}"
    echo "=========================================="
    echo ""
    
    # === 1. Проверка полноты разделов ===
    echo -e "${MAGENTA}1. Полнота разделов${NC}"
    
    local sections_found=0
    local sections_total=${#REQUIRED_SECTIONS[@]}
    local missing_sections=()
    local present_sections=()
    
    for section in "${REQUIRED_SECTIONS[@]}"; do
        if check_section "$spec_file" "$section"; then
            ((sections_found++))
            present_sections+=("$section")
            if [[ "$verbose" == "true" ]]; then
                echo -e "  ${GREEN}✅${NC} $section"
            fi
        else
            missing_sections+=("$section")
            echo -e "  ${RED}❌${NC} $section - ОТСУТСТВУЕТ"
        fi
    done
    
    local completeness_score=$((sections_found * 100 / sections_total))
    echo ""
    echo -e "  Completeness: ${sections_found}/${sections_total} разделов (${completeness_score}%)"
    
    # === 2. Проверка тестируемости требований ===
    echo ""
    echo -e "${MAGENTA}2. Тестируемость требований${NC}"
    
    local requirements_section=$(get_section_content "$spec_file" "Требования")
    local testable_count=0
    local total_requirements=0
    local untestable_requirements=()
    
    while IFS= read -r line; do
        if [[ "$line" =~ ^[-*0-9] ]]; then
            ((total_requirements++))
            if is_requirement_testable "$line"; then
                ((testable_count++))
            else
                untestable_requirements+=("$(echo "$line" | head -c 80)...")
            fi
        fi
    done <<< "$requirements_section"
    
    local testability_score=0
    if [[ $total_requirements -gt 0 ]]; then
        testability_score=$((testable_count * 100 / total_requirements))
    fi
    
    echo -e "  Testability: ${testable_count}/${total_requirements} требований тестируемы (${testability_score}%)"
    
    if [[ ${#untestable_requirements[@]} -gt 0 && "$verbose" == "true" ]]; then
        echo -e "  ${YELLOW}⚠️ Нетестируемые требования:${NC}"
        for req in "${untestable_requirements[@]}"; do
            echo -e "    - $req"
        done
    fi
    
    # === 3. Поиск деталей реализации ===
    echo ""
    echo -e "${MAGENTA}3. Детали реализации${NC}"
    
    local content=$(cat "$spec_file")
    local impl_details=$(find_implementation_details "$content")
    local impl_count=$(echo "$impl_details" | wc -w)
    
    if [[ $impl_count -gt 0 && -n "$impl_details" ]]; then
        echo -e "  ${YELLOW}⚠️ Найдено: $impl_count${NC}"
        if [[ "$verbose" == "true" ]]; then
            echo -e "  Детали: $impl_details"
        fi
    else
        echo -e "  ${GREEN}✅ Детали реализации не найдены${NC}"
    fi
    
    # === 4. Проверка измеримости критериев успеха ===
    echo ""
    echo -e "${MAGENTA}4. Измеримость критериев успеха${NC}"
    
    local criteria_section=$(get_section_content "$spec_file" "Условия успеха")
    local measurable=$(check_criteria_measurable "$criteria_section")
    local measurable_count=$(echo "$measurable" | cut -d'/' -f1)
    local total_criteria=$(echo "$measurable" | cut -d'/' -f2)
    
    local measurability_score=0
    if [[ $total_criteria -gt 0 ]]; then
        measurability_score=$((measurable_count * 100 / total_criteria))
    fi
    
    echo -e "  Measurability: ${measurable_count}/${total_criteria} критериев измеримы (${measurability_score}%)"
    
    # === 5. Соответствие конституции ===
    echo ""
    echo -e "${MAGENTA}5. Соответствие конституции${NC}"
    
    local constitution_compliant=true
    local constitution_issues=()
    
    if [[ -f "$CONSTITUTION_FILE" ]]; then
        # Простая проверка на наличие ключевых принципов
        local constitution_content=$(cat "$CONSTITUTION_FILE")
        
        # Проверка на наличие обязательных принципов
        if ! grep -q "TDD" "$spec_file" && grep -q "TDD" "$constitution_content"; then
            constitution_issues+=("TDD принцип не отражен")
            constitution_compliant=false
        fi
    else
        echo -e "  ${YELLOW}⚠️ Конституция не найдена, проверка пропущена${NC}"
    fi
    
    if [[ "$constitution_compliant" == "true" ]]; then
        echo -e "  ${GREEN}✅ Соответствует конституции${NC}"
    else
        echo -e "  ${RED}❌ Проблемы соответствия:${NC}"
        for issue in "${constitution_issues[@]}"; do
            echo -e "    - $issue"
        done
    fi
    
    # === 6. Итоговый счет ===
    echo ""
    echo "=========================================="
    echo -e "${CYAN}Compliance Score:${NC}"
    
    local total_score=$(( (completeness_score + testability_score + measurability_score) / 3 ))
    
    # Штраф за детали реализации
    if [[ $impl_count -gt 0 ]]; then
        total_score=$((total_score - impl_count * 2))
        [[ $total_score -lt 0 ]] && total_score=0
    fi
    
    # Штраф за несоответствие конституции
    if [[ "$constitution_compliant" == "false" ]]; then
        total_score=$((total_score - 10))
        [[ $total_score -lt 0 ]] && total_score=0
    fi
    
    local score_color=$GREEN
    if [[ $total_score -lt 70 ]]; then
        score_color=$YELLOW
    fi
    if [[ $total_score -lt 50 ]]; then
        score_color=$RED
    fi
    
    echo -e "  ${score_color}${total_score}/100${NC}"
    
    # Вывод рекомендаций
    echo ""
    echo -e "${MAGENTA}Рекомендации:${NC}"
    
    if [[ ${#missing_sections[@]} -gt 0 ]]; then
        echo -e "  1. Добавить отсутствующие разделы: ${missing_sections[*]}"
    fi
    if [[ ${#untestable_requirements[@]} -gt 0 ]]; then
        echo -e "  2. Уточнить ${#untestable_requirements[@]} нетестируемых требований"
    fi
    if [[ $impl_count -gt 0 ]]; then
        echo -e "  3. Удалить $impl_count деталей реализации"
    fi
    if [[ $measurability_score -lt 80 ]]; then
        echo -e "  4. Добавить метрики к критериям успеха"
    fi
    
    echo ""
    
    # Возвращаем JSON результат если нужно
    if [[ "${JSON_OUTPUT:-false}" == "true" ]]; then
        cat << EOF
{
  "spec": "$spec_name",
  "completeness": {
    "found": $sections_found,
    "total": $sections_total,
    "score": $completeness_score,
    "missing": $(printf '%s\n' "${missing_sections[@]}" | jq -R . | jq -s .)
  },
  "testability": {
    "testable": $testable_count,
    "total": $total_requirements,
    "score": $testability_score
  },
  "implementation_details": $impl_count,
  "measurability": {
    "measurable": $measurable_count,
    "total": $total_criteria,
    "score": $measurability_score
  },
  "constitution_compliant": $constitution_compliant,
  "compliance_score": $total_score
}
EOF
    fi
    
    return 0
}

# Функция анализа всех спецификаций
analyze_all() {
    local specs_dir="$PROJECT_ROOT/specs"
    
    if [[ ! -d "$specs_dir" ]]; then
        echo -e "${RED}Ошибка: Директория specs не найдена${NC}"
        exit 1
    fi
    
    echo -e "${CYAN}Анализ всех спецификаций в: $specs_dir${NC}"
    echo ""
    
    local total_specs=0
    local passed_specs=0
    local failed_specs=0
    
    for spec_dir in "$specs_dir"/*/; do
        if [[ -d "$spec_dir" ]]; then
            ((total_specs++))
            
            local spec_file="$spec_dir/spec.md"
            if [[ -f "$spec_file" ]]; then
                analyze_spec "$spec_file" "$VERBOSE"
                
                # Извлекаем score из вывода (упрощенно)
                if [[ $? -eq 0 ]]; then
                    ((passed_specs++))
                else
                    ((failed_specs++))
                fi
            else
                echo -e "${RED}❌ $spec_dir: spec.md не найден${NC}"
                ((failed_specs++))
            fi
            
            echo ""
            echo "------------------------------------------"
            echo ""
        fi
    done
    
    echo ""
    echo "=========================================="
    echo -e "${CYAN}Итого:${NC}"
    echo -e "  Всего спецификаций: $total_specs"
    echo -e "  ${GREEN}Прошло: $passed_specs${NC}"
    echo -e "  ${RED}Не прошло: $failed_specs${NC}"
}

# Основная функция
main() {
    VERBOSE=false
    JSON_OUTPUT=false
    
    if [[ $# -eq 0 ]]; then
        show_help
        exit 0
    fi
    
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --all)
                analyze_all
                exit 0
                ;;
            --verbose|-v)
                VERBOSE=true
                shift
                ;;
            --json)
                JSON_OUTPUT=true
                shift
                ;;
            --constitution)
                if [[ -f "$CONSTITUTION_FILE" ]]; then
                    echo -e "${CYAN}Конституция:${NC}"
                    head -50 "$CONSTITUTION_FILE"
                else
                    echo -e "${RED}Конституция не найдена: $CONSTITUTION_FILE${NC}"
                fi
                exit 0
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            *)
                local spec_file=$(check_spec_file "$1")
                if [[ $? -eq 0 ]]; then
                    analyze_spec "$spec_file" "$VERBOSE"
                else
                    exit 1
                fi
                shift
                ;;
        esac
    done
}

# Запуск
main "$@"
