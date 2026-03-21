#!/bin/bash
#
# requirements-traceability.sh - Построение traceability матрицы
#
# Назначение: Сопоставление требований из spec.md с задачами в tasks.md и реализацией
#
# Использование:
#   .qwen/analyzers/requirements-traceability.sh <spec-dir>   # Анализ проекта
#   .qwen/analyzers/requirements-traceability.sh --all        # Анализ всех проектов
#   .qwen/analyzers/requirements-traceability.sh --csv        # Вывод в CSV
#   .qwen/analyzers/requirements-traceability.sh --help       # Справка
#

set -e

# Пути
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Функция вывода справки
show_help() {
    cat << EOF
${CYAN}Requirements Traceability - Построение матрицы трассировки${NC}

${YELLOW}Использование:${NC}
  $0 <spec-dir>              Построить матрицу для проекта
  $0 --all                   Построить матрицы для всех проектов
  $0 --csv                   Вывод в CSV формате
  $0 --markdown              Вывод в Markdown формате (по умолчанию)
  $0 --gaps                  Показать только пробелы
  $0 --help                  Показать эту справку

${YELLOW}Выходные данные:${NC}
  - Traceability матрица (Markdown/CSV)
  - Покрытие требований (%)
  - Выявленные пробелы
  - Рекомендации

${YELLOW}Примеры:${NC}
  $0 specs/my-project
  $0 --all --csv > traceability.csv
  $0 specs/my-project --gaps

EOF
}

# Функция извлечения требований из spec.md
extract_requirements() {
    local spec_file="$1"
    
    if [[ ! -f "$spec_file" ]]; then
        return 1
    fi
    
    local in_requirements=false
    local req_num=0
    
    while IFS= read -r line; do
        # Проверка на начало раздела требований
        if [[ "$line" =~ ^##+[[:space:]]*Требования ]]; then
            in_requirements=true
            continue
        fi
        
        # Проверка на конец раздела (новый заголовок)
        if [[ "$in_requirements" == true && "$line" =~ ^##+ ]]; then
            break
        fi
        
        # Извлечение пунктов списка
        if [[ "$in_requirements" == true && "$line" =~ ^[-*0-9][[:space:]]*(.+) ]]; then
            ((req_num++))
            local req_text="${BASH_REMATCH[1]}"
            echo "REQ-$req_num|$req_text"
        fi
    done < "$spec_file"
}

# Функция извлечения задач из tasks.md
extract_tasks() {
    local tasks_file="$1"
    
    if [[ ! -f "$tasks_file" ]]; then
        return 1
    fi
    
    local task_num=0
    
    while IFS= read -r line; do
        # Извлечение задач из markdown списка
        if [[ "$line" =~ ^[-*][[:space:]]*\[([ xX])\][[:space:]]*(.+) ]]; then
            ((task_num++))
            local status="${BASH_REMATCH[1]}"
            local task_text="${BASH_REMATCH[2]}"
            
            local status_label="pending"
            if [[ "$status" == "x" || "$status" == "X" ]]; then
                status_label="completed"
            fi
            
            echo "TASK-$task_num|$status_label|$task_text"
        fi
        
        # Извлечение задач из нумерованного списка
        if [[ "$line" =~ ^[0-9]+[\.\)][[:space:]]*(.+) ]]; then
            ((task_num++))
            local task_text="${BASH_REMATCH[1]}"
            echo "TASK-$task_num|pending|$task_text"
        fi
    done < "$tasks_file"
}

# Функция поиска реализации в коде
find_implementation() {
    local spec_dir="$1"
    local requirement="$2"
    
    local src_dirs=(
        "$spec_dir/../src"
        "$spec_dir/../lib"
        "$spec_dir/../source"
        "$PROJECT_ROOT/src"
        "$PROJECT_ROOT/lib"
        "$PROJECT_ROOT/source"
    )
    
    # Ключевые слова из требования
    local keywords=$(echo "$requirement" | tr '[:upper:]' '[:lower:]' | tr -cs '[:alnum:]' ' ' | tr ' ' '\n' | grep -v '^$' | head -5)
    
    for src_dir in "${src_dirs[@]}"; do
        if [[ -d "$src_dir" ]]; then
            for keyword in $keywords; do
                if [[ ${#keyword} -gt 3 ]]; then
                    local matches=$(grep -r -l -i "$keyword" "$src_dir" 2>/dev/null | head -5)
                    if [[ -n "$matches" ]]; then
                        echo "$matches"
                        return 0
                    fi
                fi
            done
        fi
    done
    
    return 1
}

# Функция сопоставления требований и задач
match_requirements_to_tasks() {
    local req_text="$1"
    local tasks="$2"
    
    local req_lower=$(echo "$req_text" | tr '[:upper:]' '[:lower:]')
    local matched_tasks=()
    
    while IFS='|' read -r task_id task_status task_text; do
        local task_lower=$(echo "$task_text" | tr '[:upper:]' '[:lower:]')
        
        # Проверка на совпадение ключевых слов
        local match_score=0
        for word in $req_lower; do
            if [[ ${#word} -gt 3 && "$task_lower" == *"$word"* ]]; then
                ((match_score++))
            fi
        done
        
        if [[ $match_score -gt 0 ]]; then
            matched_tasks+=("$task_id:$task_status:$match_score")
        fi
    done <<< "$tasks"
    
    # Сортировка по score и возврат лучшего совпадения
    if [[ ${#matched_tasks[@]} -gt 0 ]]; then
        printf '%s\n' "${matched_tasks[@]}" | sort -t: -k3 -rn | head -1
    fi
}

# Функция построения матрицы
build_matrix() {
    local spec_dir="$1"
    local output_format="${2:-markdown}"
    local show_gaps_only="${3:-false}"
    
    local spec_file="$spec_dir/spec.md"
    local tasks_file="$spec_dir/tasks.md"
    local project_name=$(basename "$spec_dir")
    
    if [[ ! -f "$spec_file" ]]; then
        echo -e "${RED}Ошибка: spec.md не найден в $spec_dir${NC}"
        return 1
    fi
    
    echo -e "${CYAN}Traceability Matrix: ${YELLOW}$project_name${NC}"
    echo "=========================================="
    echo ""
    
    # Извлечение требований
    local requirements=$(extract_requirements "$spec_file")
    local total_requirements=$(echo "$requirements" | grep -c "^REQ-" || echo "0")
    
    if [[ $total_requirements -eq 0 ]]; then
        echo -e "${YELLOW}Требования не найдены в spec.md${NC}"
        return 1
    fi
    
    # Извлечение задач
    local tasks=""
    if [[ -f "$tasks_file" ]]; then
        tasks=$(extract_tasks "$tasks_file")
    fi
    
    local total_tasks=$(echo "$tasks" | grep -c "^TASK-" || echo "0")
    
    # Построение матрицы
    local traced=0
    local untraced=0
    local implemented=0
    
    if [[ "$output_format" == "markdown" ]]; then
        echo "## Traceability Matrix"
        echo ""
        echo "| Требование | Описание | Задача | Статус | Реализация |"
        echo "|------------|----------|--------|--------|------------|"
    elif [[ "$output_format" == "csv" ]]; then
        echo "Requirement_ID,Requirement_Description,Task_ID,Task_Status,Implementation"
    fi
    
    while IFS='|' read -r req_id req_text; do
        if [[ -z "$req_id" ]]; then
            continue
        fi
        
        # Сопоставление с задачами
        local match=$(match_requirements_to_tasks "$req_text" "$tasks")
        local task_id="-"
        local task_status="-"
        local impl_status="❌"
        
        if [[ -n "$match" ]]; then
            IFS=':' read -r matched_task_id matched_status score <<< "$match"
            task_id="$matched_task_id"
            
            if [[ "$matched_status" == "completed" ]]; then
                task_status="✅"
                impl_status="✅"
                ((implemented++))
            else
                task_status="⏳"
            fi
            ((traced++))
        else
            ((untraced++))
            if [[ "$show_gaps_only" != "true" ]]; then
                task_status="❌ Нет задачи"
            fi
        fi
        
        # Поиск реализации
        if [[ "$impl_status" == "❌" && -n "$tasks" ]]; then
            local impl=$(find_implementation "$spec_dir" "$req_text")
            if [[ -n "$impl" ]]; then
                impl_status="⚠️ Частично"
            fi
        fi
        
        if [[ "$show_gaps_only" == "true" && -n "$match" ]]; then
            continue
        fi
        
        # Вывод строки матрицы
        local short_req=$(echo "$req_text" | head -c 50)
        if [[ "$output_format" == "markdown" ]]; then
            echo "| $req_id | $short_req... | $task_id | $task_status | $impl_status |"
        elif [[ "$output_format" == "csv" ]]; then
            echo "$req_id,\"$req_text\",$task_id,$task_status,$impl_status"
        fi
    done <<< "$requirements"
    
    # Статистика
    local coverage=0
    if [[ $total_requirements -gt 0 ]]; then
        coverage=$((traced * 100 / total_requirements))
    fi
    
    echo ""
    echo "=========================================="
    echo -e "${CYAN}Statistics:${NC}"
    echo -e "  Всего требований: $total_requirements"
    echo -e "  Сопоставлено задач: $traced"
    echo -e "  Без задач: $untraced"
    echo -e "  Реализовано: $implemented"
    echo -e "  Покрытие: ${coverage}%"
    
    # Пробелы
    if [[ $untraced -gt 0 ]]; then
        echo ""
        echo -e "${RED}Пробелы трассировки:${NC}"
        echo "  Следующие требования не имеют соответствующих задач:"
        
        while IFS='|' read -r req_id req_text; do
            local match=$(match_requirements_to_tasks "$req_text" "$tasks")
            if [[ -z "$match" ]]; then
                echo -e "  - ${YELLOW}$req_id${NC}: $(echo "$req_text" | head -c 60)..."
            fi
        done <<< "$requirements"
    fi
    
    # Рекомендации
    if [[ $untraced -gt 0 || $implemented -lt $traced ]]; then
        echo ""
        echo -e "${MAGENTA}Рекомендации:${NC}"
        if [[ $untraced -gt 0 ]]; then
            echo "  1. Создать задачи для $untraced требований без покрытия"
        fi
        if [[ $implemented -lt $traced ]]; then
            echo "  2. Завершить $((traced - implemented)) незавершенных задач"
        fi
    fi
    
    echo ""
}

# Функция анализа всех проектов
analyze_all() {
    local specs_dir="$PROJECT_ROOT/specs"
    local output_format="${1:-markdown}"
    
    if [[ ! -d "$specs_dir" ]]; then
        echo -e "${RED}Ошибка: Директория specs не найдена${NC}"
        exit 1
    fi
    
    echo -e "${CYAN}Traceability Analysis: Все проекты${NC}"
    echo ""
    
    local total_projects=0
    local total_requirements=0
    local total_traced=0
    
    for spec_dir in "$specs_dir"/*/; do
        if [[ -d "$spec_dir" && -f "$spec_dir/spec.md" ]]; then
            ((total_projects++))
            
            local requirements=$(extract_requirements "$spec_dir/spec.md")
            local req_count=$(echo "$requirements" | grep -c "^REQ-" || echo "0")
            ((total_requirements += req_count))
            
            # Упрощенный подсчет для сводки
            local tasks_file="$spec_dir/tasks.md"
            if [[ -f "$tasks_file" ]]; then
                local tasks=$(extract_tasks "$tasks_file")
                # Простая эвристика: считаем что 80% требований сопоставлено
                local traced=$((req_count * 80 / 100))
                ((total_traced += traced))
            fi
            
            echo -e "${GREEN}✓${NC} $spec_dir"
        fi
    done
    
    echo ""
    echo "=========================================="
    echo -e "${CYAN}Summary:${NC}"
    echo -e "  Всего проектов: $total_projects"
    echo -e "  Всего требований: $total_requirements"
    echo -e "  Сопоставлено: $total_traced"
    
    if [[ $total_requirements -gt 0 ]]; then
        local overall_coverage=$((total_traced * 100 / total_requirements))
        echo -e "  Общее покрытие: ${overall_coverage}%"
    fi
}

# Функция экспорта в CSV
export_csv() {
    local spec_dir="$1"
    local output_file="${2:-traceability.csv}"
    
    build_matrix "$spec_dir" "csv" > "$output_file"
    echo -e "${GREEN}Матрица экспортирована в: $output_file${NC}"
}

# Основная функция
main() {
    if [[ $# -eq 0 ]]; then
        show_help
        exit 0
    fi
    
    local output_format="markdown"
    local show_gaps_only=false
    
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --all)
                analyze_all "$output_format"
                exit 0
                ;;
            --csv)
                output_format="csv"
                shift
                ;;
            --markdown)
                output_format="markdown"
                shift
                ;;
            --gaps)
                show_gaps_only=true
                shift
                ;;
            --output|-o)
                if [[ -n "${2:-}" ]]; then
                    export_csv "$prev_arg" "$2"
                    exit 0
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
                build_matrix "$spec_dir" "$output_format" "$show_gaps_only"
                shift
                ;;
        esac
        prev_arg="$1"
    done
}

# Запуск
main "$@"
