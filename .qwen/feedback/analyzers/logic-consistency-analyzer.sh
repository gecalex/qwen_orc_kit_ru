#!/bin/bash
#
# Logic Consistency Analyzer
# Назначение: Проверка логической целостности
# Версия: 1.0.0
#

set -euo pipefail

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Конфигурация
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
OUTPUT_DIR="${OUTPUT_DIR:-$SCRIPT_DIR/../reports}"
TIMESTAMP=$(date +%Y-%m-%d_%H-%M-%S)

# Переменные для сбора данных
declare -a CONTRADICTIONS=()
declare -a PATH_MISMATCHES=()
declare -a DUPLICATE_LOGIC=()
declare -a DEAD_CODE=()
declare -a RECOMMENDATIONS=()

# Метрики
TOTAL_FILES=0
DOCUMENTATION_FILES=0
CODE_FILES=0
CONTRADICTIONS_COUNT=0
PATH_ISSUES=0
DUPLICATES_COUNT=0
DEAD_CODE_COUNT=0

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

# Проверка противоречий в документации
check_documentation_contradictions() {
    log_info "Проверка противоречий в документации..."
    
    # Сбор всех markdown файлов
    local md_files
    md_files=$(find "$PROJECT_ROOT" -name "*.md" -type f 2>/dev/null | head -50)
    DOCUMENTATION_FILES=$(echo "$md_files" | wc -l)
    
    # Проверка на противоречивые утверждения
    local contradictions_patterns=(
        "должен:не должен"
        "обязательно:не обязательно"
        "требуется:не требуется"
        "всегда:никогда"
        "true:false"
        "enabled:disabled"
        "include:exclude"
    )
    
    for file in $md_files; do
        if [ -f "$file" ]; then
            local content
            content=$(cat "$file" 2>/dev/null | tr '[:upper:]' '[:lower:]' || echo "")
            
            for pattern in "${contradictions_patterns[@]}"; do
                local term1="${pattern%%:*}"
                local term2="${pattern##*:}"
                
                if echo "$content" | grep -q "$term1" && echo "$content" | grep -q "$term2"; then
                    # Проверка, что это не в одном предложении
                    local line1
                    local line2
                    line1=$(echo "$content" | grep -n "$term1" | head -1 | cut -d: -f1 || echo "0")
                    line2=$(echo "$content" | grep -n "$term2" | head -1 | cut -d: -f1 || echo "0")
                    
                    if [ "$line1" != "0" ] && [ "$line2" != "0" ] && [ "$line1" != "$line2" ]; then
                        local diff=$((line2 - line1))
                        if [ "$diff" -lt 0 ]; then
                            diff=$((-diff))
                        fi
                        
                        if [ "$diff" -gt 5 ]; then
                            CONTRADICTIONS+=("Возможное противоречие в $(basename "$file"): '$term1' и '$term2' в разных разделах")
                            ((CONTRADICTIONS_COUNT++)) || true
                        fi
                    fi
                fi
            done
        fi
    done
    
    # Проверка несоответствий версий
    local versions
    versions=$(grep -roh "v[0-9]\+\.[0-9]\+\.[0-9]\+" "$PROJECT_ROOT" --include="*.md" 2>/dev/null | sort -u || echo "")
    
    if [ -n "$versions" ]; then
        local version_count
        version_count=$(echo "$versions" | wc -l)
        
        if [ "$version_count" -gt 3 ]; then
            log_warning "Найдено несколько версий в документации: $version_count"
            CONTRADICTIONS+=("Несоответствие версий в документации: $(echo "$versions" | tr '\n' ', ')")
        fi
    fi
}

# Проверка несостыковок в путях
check_path_mismatches() {
    log_info "Проверка несостыковок в путях..."
    
    # Сбор всех путей из документации
    local path_patterns=(
        "\.qwen/[a-zA-Z/-]\+"
        "src/[a-zA-Z/-]\+"
        "lib/[a-zA-Z/-]\+"
        "scripts/[a-zA-Z/-]\+"
        "tests/[a-zA-Z/-]\+"
    )
    
    for pattern in "${path_patterns[@]}"; do
        local referenced_paths
        referenced_paths=$(grep -rohE "$pattern" "$PROJECT_ROOT" --include="*.md" 2>/dev/null | sort -u || echo "")
        
        for path in $referenced_paths; do
            # Проверка существования пути
            if [ ! -e "$PROJECT_ROOT/$path" ] && [ ! -e "$PROJECT_ROOT/${path%.md}" ]; then
                # Исключение для шаблонов и примеров
                if ! echo "$path" | grep -qE "\{.*\}|\*|example|template"; then
                    PATH_MISMATCHES+=("Путь не существует: $path")
                    ((PATH_ISSUES++)) || true
                fi
            fi
        done
    done
    
    # Проверка ссылок на несуществующие файлы
    local broken_links=0
    while IFS= read -r file; do
        if [ -f "$file" ]; then
            # Извлечение относительных ссылок
            local links
            links=$(grep -oE "\]\(\./[^)]+\)|\]\(\.\./[^)]+\)" "$file" 2>/dev/null | grep -oE "\([^)]+\)" | tr -d '()' || echo "")
            
            for link in $links; do
                local target_file
                target_file="$(dirname "$file")/$link"
                target_file=$(cd "$(dirname "$target_file")" 2>/dev/null && pwd)/$(basename "$target_file") 2>/dev/null || echo ""
                
                if [ -n "$target_file" ] && [ ! -f "$target_file" ]; then
                    ((broken_links++)) || true
                    if [ "$broken_links" -le 10 ]; then
                        PATH_MISMATCHES+=("Битая ссылка в $(basename "$file"): $link")
                    fi
                fi
            done
        fi
    done < <(find "$PROJECT_ROOT" -name "*.md" -type f 2>/dev/null | head -20)
    
    if [ "$broken_links" -gt 10 ]; then
        PATH_MISMATCHES+=("... и еще $((broken_links - 10)) битых ссылок")
    fi
    
    PATH_ISSUES=$((PATH_ISSUES + broken_links))
}

# Проверка дублирования логики
check_duplicate_logic() {
    log_info "Проверка дублирования логики..."
    
    CODE_FILES=$(find "$PROJECT_ROOT" -name "*.sh" -o -name "*.js" -o -name "*.ts" -o -name "*.py" 2>/dev/null | wc -l)
    
    # Поиск дублирующихся функций в shell скриптах
    local func_names
    func_names=$(grep -rh "^[a-z_]*\(\)" "$PROJECT_ROOT" --include="*.sh" 2>/dev/null | grep -oE "^[a-z_]+" | sort | uniq -d || echo "")
    
    for func in $func_names; do
        if [ -n "$func" ] && [ "$func" != "main" ] && [ "$func" != "init" ]; then
            local files_with_func
            files_with_func=$(grep -rl "^${func}()" "$PROJECT_ROOT" --include="*.sh" 2>/dev/null | wc -l)
            
            if [ "$files_with_func" -gt 1 ]; then
                DUPLICATE_LOGIC+=("Функция '$func' дублируется в $files_with_func файлах")
                ((DUPLICATES_COUNT++)) || true
            fi
        fi
    done
    
    # Поиск дублирующихся блоков кода (по ключевым паттернам)
    local common_patterns=(
        "set -euo pipefail"
        "SCRIPT_DIR=\$(cd"
        "log_info\(\)"
        "log_error\(\)"
        "show_help\(\)"
    )
    
    for pattern in "${common_patterns[@]}"; do
        local count
        count=$(grep -r "$pattern" "$PROJECT_ROOT" --include="*.sh" 2>/dev/null | wc -l)
        
        # Это нормально для утилитных функций, но если больше 10 - стоит вынести в общую библиотеку
        if [ "$count" -gt 10 ]; then
            RECOMMENDATIONS+=("Рассмотрите вынесение '$pattern' в общую библиотеку (используется в $count файлах)")
        fi
    done
    
    # Проверка дублирования в документации
    local doc_duplicates=0
    while IFS= read -r file1; do
        while IFS= read -r file2; do
            if [ "$file1" != "$file2" ]; then
                local content1
                local content2
                content1=$(cat "$file1" 2>/dev/null | head -50 || echo "")
                content2=$(cat "$file2" 2>/dev/null | head -50 || echo "")
                
                # Простая проверка на полное совпадение начала файлов
                if [ "$content1" = "$content2" ] && [ -n "$content1" ]; then
                    ((doc_duplicates++)) || true
                    DUPLICATE_LOGIC+=("Документы $(basename "$file1") и $(basename "$file2") имеют одинаковое содержание")
                fi
            fi
        done < <(find "$PROJECT_ROOT" -name "*.md" -type f 2>/dev/null | head -10)
        break  # Только первая итерация для производительности
    done < <(find "$PROJECT_ROOT" -name "*.md" -type f 2>/dev/null | head -10)
}

# Проверка мертвого кода
check_dead_code() {
    log_info "Проверка мертвого кода..."
    
    # Поиск неиспользуемых функций
    while IFS= read -r file; do
        if [ -f "$file" ]; then
            # Извлечение имен функций
            local functions
            functions=$(grep -E "^[a-z_]+\(\)" "$file" 2>/dev/null | grep -oE "^[a-z_]+" || echo "")
            
            for func in $functions; do
                if [ -n "$func" ] && [ "$func" != "main" ]; then
                    # Проверка вызовов функции в других файлах
                    local calls
                    calls=$(grep -r "${func}[^a-z_]" "$PROJECT_ROOT" --include="*.sh" 2>/dev/null | wc -l)
                    
                    # Если функция вызывается только 1 раз (в своем определении)
                    if [ "$calls" -le 1 ]; then
                        DEAD_CODE+=("Возможно неиспользуемая функция '$func' в $(basename "$file")")
                        ((DEAD_CODE_COUNT++)) || true
                    fi
                fi
            done
        fi
    done < <(find "$PROJECT_ROOT" -name "*.sh" -type f 2>/dev/null | head -20)
    
    # Поиск закомментированного кода
    local commented_code=0
    while IFS= read -r file; do
        if [ -f "$file" ]; then
            # Подсчет закомментированных строк кода
            local commented_lines
            commented_lines=$(grep -cE "^\s*#[^!]" "$file" 2>/dev/null || echo "0")
            local total_lines
            total_lines=$(wc -l < "$file" 2>/dev/null || echo "1")
            
            if [ "$total_lines" -gt 0 ]; then
                local percent=$((commented_lines * 100 / total_lines))
                
                if [ "$percent" -gt 30 ]; then
                    DEAD_CODE+=("Файл $(basename "$file"): $percent% закомментированного кода")
                    ((commented_code++)) || true
                fi
            fi
        fi
    done < <(find "$PROJECT_ROOT" -name "*.sh" -type f 2>/dev/null | head -20)
    
    # Поиск TODO/FIXME старше 30 дней (по git)
    if [ -d "$PROJECT_ROOT/.git" ]; then
        local old_todos
        old_todos=$(grep -rn "TODO\|FIXME\|XXX\|HACK" "$PROJECT_ROOT" --include="*.sh" --include="*.md" 2>/dev/null | head -20 || echo "")
        
        if [ -n "$old_todos" ]; then
            local todo_count
            todo_count=$(echo "$old_todos" | wc -l)
            RECOMMENDATIONS+=("Найдено $todo_count TODO/FIXME комментариев - рассмотрите их обработку")
        fi
    fi
}

# Проверка целостности ссылок между агентами
check_agent_references() {
    log_info "Проверка ссылок между агентами..."
    
    local agents_dir="$PROJECT_ROOT/.qwen/agents"
    
    if [ ! -d "$agents_dir" ]; then
        return
    fi
    
    # Сбор всех имен агентов
    local agent_names=()
    while IFS= read -r agent_file; do
        local name
        name=$(basename "$agent_file" .md)
        agent_names+=("$name")
    done < <(find "$agents_dir" -name "*.md" -type f 2>/dev/null)
    
    # Проверка ссылок на несуществующих агентов
    for agent_file in "$agents_dir"/*.md; do
        if [ -f "$agent_file" ]; then
            local content
            content=$(cat "$agent_file" 2>/dev/null || echo "")
            
            # Поиск упоминаний других агентов
            for agent_name in "${agent_names[@]}"; do
                local current_name
                current_name=$(basename "$agent_file" .md)
                
                if [ "$agent_name" != "$current_name" ]; then
                    if echo "$content" | grep -qi "$agent_name"; then
                        # Проверка существования упоминаемого агента
                        if [ ! -f "$agents_dir/${agent_name}.md" ]; then
                            CONTRADICTIONS+=("Агент $(basename "$agent_file") ссылается на несуществующего агента: $agent_name")
                        fi
                    fi
                fi
            done
        fi
    done
}

# Расчет общего score
calculate_score() {
    local score=100
    
    # Штрафы
    score=$((score - CONTRADICTIONS_COUNT * 5))
    score=$((score - PATH_ISSUES * 3))
    score=$((score - DUPLICATES_COUNT * 4))
    score=$((score - DEAD_CODE_COUNT * 2))
    
    # Ограничиваем от 0 до 100
    if [ "$score" -lt 0 ]; then
        score=0
    elif [ "$score" -gt 100 ]; then
        score=100
    fi
    
    echo "$score"
}

# Генерация JSON отчета
generate_json_report() {
    local score
    score=$(calculate_score)
    
    # Формирование массивов JSON
    local contradictions_json="[]"
    local paths_json="[]"
    local duplicates_json="[]"
    local dead_json="[]"
    local recommendations_json="[]"
    
    if [ ${#CONTRADICTIONS[@]} -gt 0 ]; then
        contradictions_json=$(printf '%s\n' "${CONTRADICTIONS[@]}" | jq -R . | jq -s .)
    fi
    
    if [ ${#PATH_MISMATCHES[@]} -gt 0 ]; then
        paths_json=$(printf '%s\n' "${PATH_MISMATCHES[@]}" | jq -R . | jq -s .)
    fi
    
    if [ ${#DUPLICATE_LOGIC[@]} -gt 0 ]; then
        duplicates_json=$(printf '%s\n' "${DUPLICATE_LOGIC[@]}" | jq -R . | jq -s .)
    fi
    
    if [ ${#DEAD_CODE[@]} -gt 0 ]; then
        dead_json=$(printf '%s\n' "${DEAD_CODE[@]}" | jq -R . | jq -s .)
    fi
    
    if [ ${#RECOMMENDATIONS[@]} -gt 0 ]; then
        recommendations_json=$(printf '%s\n' "${RECOMMENDATIONS[@]}" | jq -R . | jq -s .)
    fi
    
    # Создание JSON файла
    cat > "$OUTPUT_DIR/logic-consistency-analysis-$TIMESTAMP.json" << EOF
{
  "timestamp": "$TIMESTAMP",
  "status": "completed",
  "analyzer": "logic-consistency-analyzer",
  "version": "1.0.0",
  "project_root": "$PROJECT_ROOT",
  "contradictions": $contradictions_json,
  "path_mismatches": $paths_json,
  "duplicate_logic": $duplicates_json,
  "dead_code": $dead_json,
  "recommendations": $recommendations_json,
  "metrics": {
    "total_files": $TOTAL_FILES,
    "documentation_files": $DOCUMENTATION_FILES,
    "code_files": $CODE_FILES,
    "contradictions_count": $CONTRADICTIONS_COUNT,
    "path_issues": $PATH_ISSUES,
    "duplicates_count": $DUPLICATES_COUNT,
    "dead_code_count": $DEAD_CODE_COUNT
  },
  "score": $score,
  "grade": "$(if [ $score -ge 90 ]; then echo "A"; elif [ $score -ge 80 ]; then echo "B"; elif [ $score -ge 70 ]; then echo "C"; elif [ $score -ge 60 ]; then echo "D"; else echo "F"; fi)"
}
EOF
    
    log_success "Отчет сохранен: $OUTPUT_DIR/logic-consistency-analysis-$TIMESTAMP.json"
}

# Показать помощь
show_help() {
    cat << EOF
Logic Consistency Analyzer v1.0.0

Назначение: Проверка логической целостности

Использование:
  $(basename "$0") [OPTIONS]

Опции:
  -h, --help      Показать эту справку
  -v, --verbose   Подробный вывод
  -q, --quiet     Тихий режим (только JSON)
  -o, --output    Директория для вывода (по умолчанию: ../reports)

Примеры:
  $(basename "$0")                    # Запуск с настройками по умолчанию
  $(basename "$0") -o /tmp/reports    # Вывод в другую директорию
  $(basename "$0") -q                 # Тихий режим

Проверки:
  1. Противоречия в документации
  2. Несостыковки в путях
  3. Дублирование логики
  4. Мертвый код

Выход:
  JSON с противоречиями
EOF
}

# Парсинг аргументов
VERBOSE=false
QUIET=false

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
        *)
            log_error "Неизвестная опция: $1"
            show_help
            exit 1
            ;;
    esac
done

# Создание директории вывода
mkdir -p "$OUTPUT_DIR"

# Основной запуск
main() {
    if [ "$QUIET" = false ]; then
        echo "========================================"
        echo "  Logic Consistency Analyzer v1.0.0"
        echo "========================================"
        echo ""
    fi
    
    TOTAL_FILES=$(find "$PROJECT_ROOT" -type f \( -name "*.md" -o -name "*.sh" -o -name "*.js" -o -name "*.ts" \) 2>/dev/null | wc -l)
    
    check_documentation_contradictions
    check_path_mismatches
    check_duplicate_logic
    check_dead_code
    check_agent_references
    
    generate_json_report
    
    if [ "$QUIET" = false ]; then
        echo ""
        echo "========================================"
        echo "  Анализ завершен"
        echo "========================================"
        
        local score
        score=$(calculate_score)
        
        if [ "$score" -ge 90 ]; then
            log_success "Оценка: $score/100 (Отлично)"
        elif [ "$score" -ge 70 ]; then
            log_warning "Оценка: $score/100 (Требуется улучшение)"
        else
            log_error "Оценка: $score/100 (Критические проблемы)"
        fi
        
        echo ""
        echo "Всего файлов: $TOTAL_FILES"
        echo "Документация: $DOCUMENTATION_FILES, Код: $CODE_FILES"
        echo ""
        echo "Противоречия: $CONTRADICTIONS_COUNT"
        echo "Проблемы путей: $PATH_ISSUES"
        echo "Дубликаты: $DUPLICATES_COUNT"
        echo "Мертвый код: $DEAD_CODE_COUNT"
        echo "Рекомендации: ${#RECOMMENDATIONS[@]}"
    fi
}

main
