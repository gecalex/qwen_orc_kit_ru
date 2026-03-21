#!/bin/bash
#
# spec-quality-metrics.sh - Метрики качества спецификаций
#
# Назначение: Расчет и вывод метрик качества spec.md
#
# Использование:
#   .qwen/analyzers/spec-quality-metrics.sh <spec-dir>   # Метрики проекта
#   .qwen/analyzers/spec-quality-metrics.sh --all        # Метрики всех проектов
#   .qwen/analyzers/spec-quality-metrics.sh --json       # Вывод в JSON
#   .qwen/analyzers/spec-quality-metrics.sh --help       # Справка
#

set -e

# Пути
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Обязательные разделы
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
${CYAN}Spec Quality Metrics - Метрики качества спецификаций${NC}

${YELLOW}Использование:${NC}
  $0 <spec-dir>              Расчет метрик для проекта
  $0 --all                   Расчет метрик для всех проектов
  $0 --json                  Вывод в JSON формате
  $0 --threshold <N>         Порог качества (0-100, по умолчанию 70)
  $0 --help                  Показать эту справку

${YELLOW}Метрики:${NC}
  - Полнота разделов (%)         - Наличие обязательных разделов
  - Тестируемость требований (%) - Требования с четкими критериями
  - Детали реализации (count)    - Количество деталей реализации
  - Измеримость критериев (%)    - Критерии с метриками
  - Traceability coverage (%)    - Покрытие требованиями задач

${YELLOW}Примеры:${NC}
  $0 specs/my-project
  $0 --all --json > metrics.json
  $0 specs/my-project --threshold 80

EOF
}

# Функция проверки наличия раздела
check_section_exists() {
    local file="$1"
    local section="$2"
    
    grep -qi "^##*[[:space:]]*$section" "$file" 2>/dev/null
}

# Функция подсчета разделов
count_sections() {
    local file="$1"
    grep -c "^##" "$file" 2>/dev/null || echo "0"
}

# Функция подсчета слов
count_words() {
    local file="$1"
    wc -w < "$file" 2>/dev/null || echo "0"
}

# Функция извлечения содержимого раздела
get_section_content() {
    local file="$1"
    local section="$2"
    
    awk -v section="$section" '
        BEGIN { in_section = 0 }
        /^[##]+[[:space:]]+/ {
            if (in_section) exit
            header = $0
            gsub(/^[##]+[[:space:]]+/, "", header)
            if (tolower(header) == tolower(section)) {
                in_section = 1
                next
            }
        }
        in_section { print }
    ' "$file"
}

# Функция расчета полноты разделов
calculate_completeness() {
    local file="$1"
    
    local found=0
    local total=${#REQUIRED_SECTIONS[@]}
    
    for section in "${REQUIRED_SECTIONS[@]}"; do
        if check_section_exists "$file" "$section"; then
            ((found++))
        fi
    done
    
    local score=$((found * 100 / total))
    echo "$found|$total|$score"
}

# Функция расчета тестируемости требований
calculate_testability() {
    local file="$1"
    
    local requirements=$(get_section_content "$file" "Требования")
    local testable=0
    local total=0
    
    while IFS= read -r line; do
        if [[ "$line" =~ ^[-*0-9] ]]; then
            ((total++))
            
            local line_lower=$(echo "$line" | tr '[:upper:]' '[:lower:]')
            
            # Паттерны тестируемых требований
            if [[ "$line_lower" =~ (должен|необходимо|обязан|требуется|критерий|проверка|тест|валид) ]] || \
               [[ "$line" =~ [0-9]+ ]] || \
               [[ "$line_lower" =~ (все|полный|ноль|без) ]]; then
                ((testable++))
            fi
        fi
    done <<< "$requirements"
    
    local score=0
    if [[ $total -gt 0 ]]; then
        score=$((testable * 100 / total))
    fi
    
    echo "$testable|$total|$score"
}

# Функция подсчета деталей реализации
count_implementation_details() {
    local file="$1"
    
    local content=$(cat "$file")
    local count=0
    
    # Паттерны деталей реализации
    local patterns=(
        "function" "method" "class" "variable"
        "useEffect" "useState" "async" "await"
        "interface" "implementation" "controller"
        "model" "view" "component" "API"
        "endpoint" "route" "библиотека" "фреймворк"
    )
    
    local content_lower=$(echo "$content" | tr '[:upper:]' '[:lower:]')
    
    for pattern in "${patterns[@]}"; do
        local pattern_lower=$(echo "$pattern" | tr '[:upper:]' '[:lower:]')
        local matches=$(echo "$content_lower" | grep -o -i "$pattern_lower" | wc -l)
        ((count += matches))
    done
    
    echo "$count"
}

# Функция расчета измеримости критериев
calculate_measurability() {
    local file="$1"
    
    local criteria=$(get_section_content "$file" "Условия успеха")
    local measurable=0
    local total=0
    
    while IFS= read -r line; do
        if [[ "$line" =~ ^[-*] ]]; then
            ((total++))
            
            # Проверка на измеримость
            if [[ "$line" =~ [0-9]+ ]] || \
               [[ "$line" =~ (секунд|минут|часов|мс|%) ]] || \
               [[ "$line" =~ (все|полный|100|ноль|без) ]]; then
                ((measurable++))
            fi
        fi
    done <<< "$criteria"
    
    local score=0
    if [[ $total -gt 0 ]]; then
        score=$((measurable * 100 / total))
    fi
    
    echo "$measurable|$total|$score"
}

# Функция расчета traceability coverage
calculate_traceability() {
    local spec_dir="$1"
    
    local spec_file="$spec_dir/spec.md"
    local tasks_file="$spec_dir/tasks.md"
    
    if [[ ! -f "$tasks_file" ]]; then
        echo "0|0|0"
        return
    fi
    
    # Подсчет требований
    local requirements=$(get_section_content "$spec_file" "Требования")
    local req_count=$(echo "$requirements" | grep -c "^[-*0-9]" || echo "0")
    
    # Подсчет задач
    local task_count=$(grep -c "^[-*][[:space:]]*\[" "$tasks_file" 2>/dev/null || echo "0")
    
    # Эвристика: покрытие = мин(100, задачи/требования * 100)
    local coverage=0
    if [[ $req_count -gt 0 ]]; then
        coverage=$((task_count * 100 / req_count))
        [[ $coverage -gt 100 ]] && coverage=100
    fi
    
    echo "$task_count|$req_count|$coverage"
}

# Функция расчета общего качества
calculate_overall_quality() {
    local completeness="$1"
    local testability="$2"
    local impl_details="$3"
    local measurability="$4"
    local traceability="$5"
    
    # Среднее взвешенное
    local score=$(( (completeness * 30 + testability * 25 + measurability * 20 + traceability * 25) / 100 ))
    
    # Штраф за детали реализации
    if [[ $impl_details -gt 0 ]]; then
        local penalty=$((impl_details * 2))
        [[ $penalty -gt 20 ]] && penalty=20
        score=$((score - penalty))
    fi
    
    [[ $score -lt 0 ]] && score=0
    [[ $score -gt 100 ]] && score=100
    
    echo "$score"
}

# Функция вывода метрик
print_metrics() {
    local spec_dir="$1"
    local output_format="${2:-text}"
    local threshold="${3:-70}"
    
    local spec_file="$spec_dir/spec.md"
    local project_name=$(basename "$spec_dir")
    
    if [[ ! -f "$spec_file" ]]; then
        echo -e "${RED}Ошибка: spec.md не найден${NC}"
        return 1
    fi
    
    # Расчет всех метрик
    local completeness_data=$(calculate_completeness "$spec_file")
    local testability_data=$(calculate_testability "$spec_file")
    local impl_details=$(count_implementation_details "$spec_file")
    local measurability_data=$(calculate_measurability "$spec_file")
    local traceability_data=$(calculate_traceability "$spec_dir")
    
    # Извлечение значений
    IFS='|' read -r comp_found comp_total comp_score <<< "$completeness_data"
    IFS='|' read -r test_found test_total test_score <<< "$testability_data"
    IFS='|' read -r meas_found meas_total meas_score <<< "$measurability_data"
    IFS='|' read -r trace_found trace_total trace_score <<< "$traceability_data"
    
    # Общий score
    local overall_score=$(calculate_overall_quality "$comp_score" "$test_score" "$impl_details" "$meas_score" "$trace_score")
    
    # Определение статуса
    local status="✅ PASS"
    local status_color=$GREEN
    if [[ $overall_score -lt $threshold ]]; then
        status="❌ FAIL"
        status_color=$RED
    elif [[ $overall_score -lt $((threshold + 10)) ]]; then
        status="⚠️ WARNING"
        status_color=$YELLOW
    fi
    
    if [[ "$output_format" == "json" ]]; then
        cat << EOF
{
  "project": "$project_name",
  "timestamp": "$(date -Iseconds)",
  "metrics": {
    "completeness": {
      "found": $comp_found,
      "total": $comp_total,
      "score": $comp_score
    },
    "testability": {
      "testable": $test_found,
      "total": $test_total,
      "score": $test_score
    },
    "implementation_details": $impl_details,
    "measurability": {
      "measurable": $meas_found,
      "total": $meas_total,
      "score": $meas_score
    },
    "traceability": {
      "tasks": $trace_found,
      "requirements": $trace_total,
      "coverage": $trace_score
    }
  },
  "overall_score": $overall_score,
  "threshold": $threshold,
  "status": "$status"
}
EOF
    else
        # Текстовый вывод
        echo -e "${CYAN}Specification Quality Metrics: ${YELLOW}$project_name${NC}"
        echo "=========================================="
        echo ""
        
        echo -e "${MAGENTA}Полнота разделов:${NC}"
        echo "  ${comp_found}/${comp_total} разделов (${comp_score}%)"
        local bar=$(printf '%*s' $((comp_score / 5)) '' | tr ' ' '█')
        echo -e "  ${GREEN}$bar${NC}"
        echo ""
        
        echo -e "${MAGENTA}Тестируемость требований:${NC}"
        echo "  ${test_found}/${test_total} требований тестируемы (${test_score}%)"
        bar=$(printf '%*s' $((test_score / 5)) '' | tr ' ' '█')
        echo -e "  ${GREEN}$bar${NC}"
        echo ""
        
        echo -e "${MAGENTA}Детали реализации:${NC}"
        if [[ $impl_details -eq 0 ]]; then
            echo -e "  ${GREEN}✅ Не найдено${NC}"
        else
            echo -e "  ${YELLOW}⚠️ Найдено: $impl_details${NC}"
        fi
        echo ""
        
        echo -e "${MAGENTA}Измеримость критериев:${NC}"
        echo "  ${meas_found}/${meas_total} критериев измеримы (${meas_score}%)"
        bar=$(printf '%*s' $((meas_score / 5)) '' | tr ' ' '█')
        echo -e "  ${GREEN}$bar${NC}"
        echo ""
        
        echo -e "${MAGENTA}Traceability Coverage:${NC}"
        echo "  ${trace_found}/${trace_total} требований покрыты задачами (${trace_score}%)"
        bar=$(printf '%*s' $((trace_score / 5)) '' | tr ' ' '█')
        echo -e "  ${GREEN}$bar${NC}"
        echo ""
        
        echo "=========================================="
        echo -e "${CYAN}Overall Quality Score:${NC}"
        echo -e "  ${status_color}${status}${NC}"
        echo -e "  Score: ${overall_score}/100 (threshold: $threshold)"
        echo ""
    fi
}

# Функция анализа всех проектов
analyze_all() {
    local specs_dir="$PROJECT_ROOT/specs"
    local output_format="${1:-text}"
    local threshold="${2:-70}"
    
    if [[ ! -d "$specs_dir" ]]; then
        echo -e "${RED}Ошибка: Директория specs не найдена${NC}"
        exit 1
    fi
    
    local projects=()
    local scores=()
    
    for spec_dir in "$specs_dir"/*/; do
        if [[ -d "$spec_dir" && -f "$spec_dir/spec.md" ]]; then
            local project_name=$(basename "$spec_dir")
            projects+=("$project_name")
            
            # Расчет score
            local spec_file="$spec_dir/spec.md"
            local completeness_data=$(calculate_completeness "$spec_file")
            local testability_data=$(calculate_testability "$spec_file")
            local impl_details=$(count_implementation_details "$spec_file")
            local measurability_data=$(calculate_measurability "$spec_file")
            local traceability_data=$(calculate_traceability "$spec_dir")
            
            IFS='|' read -r _ _ comp_score <<< "$completeness_data"
            IFS='|' read -r _ _ test_score <<< "$testability_data"
            IFS='|' read -r _ _ meas_score <<< "$measurability_data"
            IFS='|' read -r _ _ trace_score <<< "$traceability_data"
            
            local overall=$(calculate_overall_quality "$comp_score" "$test_score" "$impl_details" "$meas_score" "$trace_score")
            scores+=("$overall")
            
            if [[ "$output_format" == "text" ]]; then
                local status="✅"
                [[ $overall -lt $threshold ]] && status="❌"
                echo -e "$status $project_name: $overall/100"
            fi
        fi
    done
    
    # Сводка
    if [[ ${#projects[@]} -gt 0 ]]; then
        local total=0
        for score in "${scores[@]}"; do
            ((total += score))
        done
        local avg=$((total / ${#scores[@]}))
        
        echo ""
        echo "=========================================="
        echo -e "${CYAN}Summary:${NC}"
        echo -e "  Проектов: ${#projects[@]}"
        echo -e "  Средний score: $avg/100"
        
        if [[ "$output_format" == "json" ]]; then
            echo "{"
            echo "  \"summary\": {"
            echo "    \"total_projects\": ${#projects[@]},"
            echo "    \"average_score\": $avg,"
            echo "    \"threshold\": $threshold"
            echo "  },"
            echo "  \"projects\": ["
            for i in "${!projects[@]}"; do
                local comma=","
                [[ $i -eq $((${#projects[@]} - 1)) ]] && comma=""
                echo "    {\"name\": \"${projects[$i]}\", \"score\": ${scores[$i]}}$comma"
            done
            echo "  ]"
            echo "}"
        fi
    fi
}

# Основная функция
main() {
    if [[ $# -eq 0 ]]; then
        show_help
        exit 0
    fi
    
    local output_format="text"
    local threshold=70
    
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --all)
                analyze_all "$output_format" "$threshold"
                exit 0
                ;;
            --json)
                output_format="json"
                shift
                ;;
            --threshold)
                if [[ -n "${2:-}" ]]; then
                    threshold="$2"
                    shift
                fi
                shift
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            *)
                local spec_dir="$1"
                if [[ ! -d "$spec_dir" ]]; then
                    echo -e "${RED}Ошибка: Директория не найдена: $spec_dir${NC}"
                    exit 1
                fi
                print_metrics "$spec_dir" "$output_format" "$threshold"
                shift
                ;;
        esac
    done
}

# Запуск
main "$@"
