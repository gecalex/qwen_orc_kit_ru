#!/bin/bash
#
# Specification Compliance Analyzer
# Назначение: Проверка соответствия спецификациям
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
SPEC_DIR="${SPEC_DIR:-$PROJECT_ROOT/specs}"
TIMESTAMP=$(date +%Y-%m-%d_%H-%M-%S)

# Переменные для сбора данных
declare -a COMPLIANCE_ISSUES=()
declare -a MISSING_SPECS=()
declare -a IMPLEMENTATION_GAPS=()
declare -a RECOMMENDATIONS=()

# Метрики
TOTAL_SPECS=0
COMPLIANT_SPECS=0
PARTIAL_SPECS=0
NON_COMPLIANT_SPECS=0
TOTAL_REQUIREMENTS=0
IMPLEMENTED_REQUIREMENTS=0
DOCUMENTED_REQUIREMENTS=0
TESTABLE_REQUIREMENTS=0

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

# Проверка наличия директории спецификаций
check_spec_directory() {
    log_info "Проверка директории спецификаций: $SPEC_DIR"
    
    if [ ! -d "$SPEC_DIR" ]; then
        log_warning "Директория спецификаций не найдена: $SPEC_DIR"
        MISSING_SPECS+=("Директория спецификаций отсутствует")
        return 1
    fi
    
    # Поиск spec.md файлов
    local spec_files
    spec_files=$(find "$SPEC_DIR" -name "spec.md" -o -name "specification.md" -o -name "*.spec.md" 2>/dev/null | wc -l)
    TOTAL_SPECS=$spec_files
    
    if [ "$TOTAL_SPECS" -eq 0 ]; then
        log_warning "Файлы spec.md не найдены"
        MISSING_SPECS+=("Отсутствуют файлы spec.md в $SPEC_DIR")
        return 1
    fi
    
    log_success "Найдено спецификаций: $TOTAL_SPECS"
    return 0
}

# Анализ наличия spec.md
check_spec_existence() {
    log_info "Проверка наличия spec.md файлов..."
    
    if [ ! -d "$SPEC_DIR" ]; then
        return
    fi
    
    while IFS= read -r spec_file; do
        if [ -n "$spec_file" ]; then
            local spec_name
            spec_name=$(basename "$(dirname "$spec_file")")
            
            # Проверка размера файла
            local file_size
            file_size=$(wc -c < "$spec_file" 2>/dev/null || echo "0")
            
            if [ "$file_size" -lt 100 ]; then
                COMPLIANCE_ISSUES+=("Спецификация $spec_name слишком короткая ($file_size байт)")
                ((NON_COMPLIANT_SPECS++))
            else
                ((COMPLIANT_SPECS++))
            fi
            
            # Проверка наличия обязательных разделов
            check_spec_sections "$spec_file" "$spec_name"
        fi
    done < <(find "$SPEC_DIR" -name "spec.md" -o -name "specification.md" 2>/dev/null)
}

# Проверка разделов спецификации
check_spec_sections() {
    local spec_file="$1"
    local spec_name="$2"
    
    local required_sections=("Описание" "Требования" "Контекст" "Критерии")
    local missing_sections=()
    
    for section in "${required_sections[@]}"; do
        if ! grep -qi "$section" "$spec_file" 2>/dev/null; then
            # Проверка на английском
            if ! grep -qi "$(echo "$section" | tr 'А-Я' 'A-Z')" "$spec_file" 2>/dev/null; then
                missing_sections+=("$section")
            fi
        fi
    done
    
    if [ ${#missing_sections[@]} -gt 0 ]; then
        COMPLIANCE_ISSUES+=("Спецификация $spec_name: отсутствуют разделы: ${missing_sections[*]}")
    fi
}

# Проверка соответствия реализации спецификации
check_implementation_compliance() {
    log_info "Проверка соответствия реализации..."
    
    if [ ! -d "$SPEC_DIR" ]; then
        return
    fi
    
    while IFS= read -r spec_file; do
        if [ -n "$spec_file" ]; then
            local spec_name
            spec_name=$(basename "$(dirname "$spec_file")")
            local spec_dir
            spec_dir=$(dirname "$spec_file")
            
            # Извлечение требований из спецификации
            local requirements
            requirements=$(grep -E "^[-*] \[.|^\d+\." "$spec_file" 2>/dev/null | wc -l || echo "0")
            TOTAL_REQUIREMENTS=$((TOTAL_REQUIREMENTS + requirements))
            
            # Проверка наличия реализованных файлов
            local impl_files=0
            
            # Проверка директории src/
            if [ -d "$PROJECT_ROOT/src" ]; then
                impl_files=$(find "$PROJECT_ROOT/src" -name "*${spec_name}*" 2>/dev/null | wc -l || echo "0")
            fi
            
            # Проверка директории .qwen/agents/
            if [ -d "$PROJECT_ROOT/.qwen/agents" ]; then
                local agent_files
                agent_files=$(find "$PROJECT_ROOT/.qwen/agents" -name "*${spec_name}*" 2>/dev/null | wc -l || echo "0")
                impl_files=$((impl_files + agent_files))
            fi
            
            # Проверка директории scripts/
            if [ -d "$PROJECT_ROOT/scripts" ]; then
                local script_files
                script_files=$(find "$PROJECT_ROOT/scripts" -name "*${spec_name}*" 2>/dev/null | wc -l || echo "0")
                impl_files=$((impl_files + script_files))
            fi
            
            if [ "$impl_files" -eq 0 ] && [ "$requirements" -gt 0 ]; then
                IMPLEMENTATION_GAPS+=("Спецификация $spec_name: нет файлов реализации для $requirements требований")
                ((PARTIAL_SPECS++))
            elif [ "$impl_files" -gt 0 ]; then
                IMPLEMENTED_REQUIREMENTS=$((IMPLEMENTED_REQUIREMENTS + requirements))
                ((COMPLIANT_SPECS++))
            fi
        fi
    done < <(find "$SPEC_DIR" -name "spec.md" -o -name "specification.md" 2>/dev/null)
}

# Проверка полноты документации
check_documentation_completeness() {
    log_info "Проверка полноты документации..."
    
    # Проверка наличия README
    if [ -f "$PROJECT_ROOT/README.md" ]; then
        DOCUMENTED_REQUIREMENTS=$((DOCUMENTED_REQUIREMENTS + 1))
    else
        COMPLIANCE_ISSUES+=("Отсутствует README.md")
    fi
    
    # Проверка наличия CHANGELOG
    if [ -f "$PROJECT_ROOT/CHANGELOG.md" ]; then
        DOCUMENTED_REQUIREMENTS=$((DOCUMENTED_REQUIREMENTS + 1))
    else
        COMPLIANCE_ISSUES+=("Отсутствует CHANGELOG.md")
    fi
    
    # Проверка наличия CONTRIBUTING
    if [ -f "$PROJECT_ROOT/CONTRIBUTING.md" ]; then
        DOCUMENTED_REQUIREMENTS=$((DOCUMENTED_REQUIREMENTS + 1))
    fi
    
    # Проверка документации агентов
    if [ -d "$PROJECT_ROOT/.qwen/agents" ]; then
        local agents_with_docs=0
        local total_agents
        total_agents=$(find "$PROJECT_ROOT/.qwen/agents" -name "*.md" 2>/dev/null | wc -l || echo "0")
        
        while IFS= read -r agent_file; do
            if [ -n "$agent_file" ]; then
                local content
                content=$(cat "$agent_file" 2>/dev/null || echo "")
                if [ -n "$content" ] && [ ${#content} -gt 100 ]; then
                    ((agents_with_docs++))
                fi
            fi
        done < <(find "$PROJECT_ROOT/.qwen/agents" -name "*.md" 2>/dev/null)
        
        if [ "$total_agents" -gt 0 ] && [ "$agents_with_docs" -lt "$total_agents" ]; then
            COMPLIANCE_ISSUES+=("Не все агенты имеют документацию: $agents_with_docs/$total_agents")
        fi
    fi
    
    # Проверка наличия инструкций
    local instruction_files=0
    for instr in "INSTALLATION.md" "USAGE_INSTRUCTIONS.md" "QUICKSTART.md"; do
        if [ -f "$PROJECT_ROOT/$instr" ]; then
            ((instruction_files++))
        fi
    done
    
    if [ "$instruction_files" -lt 2 ]; then
        COMPLIANCE_ISSUES+=("Недостаточно инструкций: найдено $instruction_files из 3")
        RECOMMENDATIONS+=("Добавьте недостающие файлы инструкций (INSTALLATION.md, USAGE_INSTRUCTIONS.md, QUICKSTART.md)")
    fi
}

# Проверка тестируемости требований
check_testability() {
    log_info "Проверка тестируемости требований..."
    
    if [ ! -d "$SPEC_DIR" ]; then
        return
    fi
    
    while IFS= read -r spec_file; do
        if [ -n "$spec_file" ]; then
            local spec_name
            spec_name=$(basename "$(dirname "$spec_file")")
            
            # Поиск критериев приемки
            local acceptance_criteria
            acceptance_criteria=$(grep -ciE "(критерий|acceptance|должен|must|should)" "$spec_file" 2>/dev/null || echo "0")
            
            if [ "$acceptance_criteria" -eq 0 ]; then
                COMPLIANCE_ISSUES+=("Спецификация $spec_name: отсутствуют критерии приемки")
                RECOMMENDATIONS+=("Добавьте критерии приемки в спецификацию $spec_name")
            else
                TESTABLE_REQUIREMENTS=$((TESTABLE_REQUIREMENTS + acceptance_criteria))
            fi
            
            # Поиск тестов для спецификации
            local test_files=0
            
            if [ -d "$PROJECT_ROOT/tests" ]; then
                test_files=$(find "$PROJECT_ROOT/tests" -name "*${spec_name}*" -o -name "*test*" 2>/dev/null | wc -l || echo "0")
            fi
            
            if [ -d "$PROJECT_ROOT/.qwen/scripts" ]; then
                local script_tests
                script_tests=$(find "$PROJECT_ROOT/.qwen/scripts" -name "*test*" 2>/dev/null | wc -l || echo "0")
                test_files=$((test_files + script_tests))
            fi
            
            if [ "$test_files" -eq 0 ] && [ "$acceptance_criteria" -gt 0 ]; then
                IMPLEMENTATION_GAPS+=("Спецификация $spec_name: нет тестов для $acceptance_criteria критериев")
            fi
        fi
    done < <(find "$SPEC_DIR" -name "spec.md" -o -name "specification.md" 2>/dev/null)
}

# Расчет метрик compliance
calculate_metrics() {
    # Общий score compliance
    local score=100
    
    # Штрафы
    score=$((score - ${#COMPLIANCE_ISSUES[@]} * 5))
    score=$((score - ${#IMPLEMENTATION_GAPS[@]} * 3))
    score=$((score - ${#MISSING_SPECS[@]} * 10))
    
    # Бонусы за документацию
    if [ "$DOCUMENTED_REQUIREMENTS" -ge 5 ]; then
        score=$((score + 5))
    fi
    
    # Бонусы за тестируемость
    if [ "$TESTABLE_REQUIREMENTS" -gt 0 ]; then
        score=$((score + 5))
    fi
    
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
    score=$(calculate_metrics)
    
    # Формирование массивов JSON
    local issues_json="[]"
    local missing_json="[]"
    local gaps_json="[]"
    local recommendations_json="[]"
    
    if [ ${#COMPLIANCE_ISSUES[@]} -gt 0 ]; then
        issues_json=$(printf '%s\n' "${COMPLIANCE_ISSUES[@]}" | jq -R . | jq -s .)
    fi
    
    if [ ${#MISSING_SPECS[@]} -gt 0 ]; then
        missing_json=$(printf '%s\n' "${MISSING_SPECS[@]}" | jq -R . | jq -s .)
    fi
    
    if [ ${#IMPLEMENTATION_GAPS[@]} -gt 0 ]; then
        gaps_json=$(printf '%s\n' "${IMPLEMENTATION_GAPS[@]}" | jq -R . | jq -s .)
    fi
    
    if [ ${#RECOMMENDATIONS[@]} -gt 0 ]; then
        recommendations_json=$(printf '%s\n' "${RECOMMENDATIONS[@]}" | jq -R . | jq -s .)
    fi
    
    # Расчет процентов
    local compliance_percent=0
    if [ "$TOTAL_SPECS" -gt 0 ]; then
        compliance_percent=$((COMPLIANT_SPECS * 100 / TOTAL_SPECS))
    fi
    
    local implementation_percent=0
    if [ "$TOTAL_REQUIREMENTS" -gt 0 ]; then
        implementation_percent=$((IMPLEMENTED_REQUIREMENTS * 100 / TOTAL_REQUIREMENTS))
    fi
    
    # Создание JSON файла
    cat > "$OUTPUT_DIR/spec-compliance-analysis-$TIMESTAMP.json" << EOF
{
  "timestamp": "$TIMESTAMP",
  "status": "completed",
  "analyzer": "spec-compliance-analyzer",
  "version": "1.0.0",
  "project_root": "$PROJECT_ROOT",
  "spec_directory": "$SPEC_DIR",
  "compliance_issues": $issues_json,
  "missing_specs": $missing_json,
  "implementation_gaps": $gaps_json,
  "recommendations": $recommendations_json,
  "metrics": {
    "total_specs": $TOTAL_SPECS,
    "compliant_specs": $COMPLIANT_SPECS,
    "partial_specs": $PARTIAL_SPECS,
    "non_compliant_specs": $NON_COMPLIANT_SPECS,
    "total_requirements": $TOTAL_REQUIREMENTS,
    "implemented_requirements": $IMPLEMENTED_REQUIREMENTS,
    "documented_requirements": $DOCUMENTED_REQUIREMENTS,
    "testable_requirements": $TESTABLE_REQUIREMENTS,
    "compliance_percent": $compliance_percent,
    "implementation_percent": $implementation_percent
  },
  "score": $score,
  "grade": "$(if [ $score -ge 90 ]; then echo "A"; elif [ $score -ge 80 ]; then echo "B"; elif [ $score -ge 70 ]; then echo "C"; elif [ $score -ge 60 ]; then echo "D"; else echo "F"; fi)"
}
EOF
    
    log_success "Отчет сохранен: $OUTPUT_DIR/spec-compliance-analysis-$TIMESTAMP.json"
}

# Показать помощь
show_help() {
    cat << EOF
Specification Compliance Analyzer v1.0.0

Назначение: Проверка соответствия спецификациям

Использование:
  $(basename "$0") [OPTIONS]

Опции:
  -h, --help          Показать эту справку
  -v, --verbose       Подробный вывод
  -q, --quiet         Тихий режим (только JSON)
  -o, --output        Директория для вывода (по умолчанию: ../reports)
  -s, --spec-dir      Директория спецификаций (по умолчанию: .qwen/specify/specs)

Примеры:
  $(basename "$0")                          # Запуск с настройками по умолчанию
  $(basename "$0") -s /path/to/specs        # Указать директорию спецификаций
  $(basename "$0") -q                       # Тихий режим

Проверки:
  1. Наличие spec.md
  2. Соответствие реализации spec
  3. Полнота документации
  4. Тестируемость требований

Выход:
  JSON с compliance метриками
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
        -s|--spec-dir)
            SPEC_DIR="$2"
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
        echo "  Specification Compliance Analyzer v1.0.0"
        echo "========================================"
        echo ""
    fi
    
    if check_spec_directory; then
        check_spec_existence
        check_implementation_compliance
        check_documentation_completeness
        check_testability
    fi
    
    generate_json_report
    
    if [ "$QUIET" = false ]; then
        echo ""
        echo "========================================"
        echo "  Анализ завершен"
        echo "========================================"
        
        local score
        score=$(calculate_metrics)
        
        if [ "$score" -ge 90 ]; then
            log_success "Оценка: $score/100 (Отлично)"
        elif [ "$score" -ge 70 ]; then
            log_warning "Оценка: $score/100 (Требуется улучшение)"
        else
            log_error "Оценка: $score/100 (Критические проблемы)"
        fi
        
        echo ""
        echo "Всего спецификаций: $TOTAL_SPECS"
        echo "Соответствуют: $COMPLIANT_SPECS"
        echo "Частично: $PARTIAL_SPECS"
        echo "Не соответствуют: $NON_COMPLIANT_SPECS"
        echo ""
        echo "Проблемы соответствия: ${#COMPLIANCE_ISSUES[@]}"
        echo "Пробелы реализации: ${#IMPLEMENTATION_GAPS[@]}"
        echo "Рекомендации: ${#RECOMMENDATIONS[@]}"
    fi
}

main
