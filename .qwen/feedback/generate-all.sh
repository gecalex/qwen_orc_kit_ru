#!/bin/bash
#
# Generate All - Главный скрипт системы обратной связи
# Назначение: Интеграция всех проверок и генерация отчетов
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
NC='\033[0m' # No Color

# Конфигурация
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
ANALYZERS_DIR="$SCRIPT_DIR/analyzers"
REPORTERS_DIR="$SCRIPT_DIR/reporters"
REPORTS_DIR="$SCRIPT_DIR/reports"
TIMESTAMP=$(date +%Y-%m-%d_%H-%M-%S)
DATE=$(date +%Y-%m-%d)

# Переменные состояния
declare -a ANALYZER_RESULTS=()
declare -a ERRORS=()
TOTAL_START_TIME=$(date +%s)

# Флаги выполнения
RUN_GIT_WORKFLOW=true
RUN_SPEC_COMPLIANCE=true
RUN_AGENT_INTERACTION=true
RUN_LOGIC_CONSISTENCY=true
RUN_QUALITY_TRENDS=true
RUN_AGENT_ANALYTICS=true
RUN_CHECKLIST_VALIDATION=true
GENERATE_REPORT=true
GENERATE_METRICS=true

# Формат вывода
OUTPUT_FORMAT="both"  # md, json, both
OUTPUT_DIR="$REPORTS_DIR"

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

# Проверка зависимостей
check_dependencies() {
    log_step "Проверка зависимостей..."
    
    local missing=()
    
    # Проверка jq
    if ! command -v jq &> /dev/null; then
        missing+=("jq")
    fi
    
    # Проверка git
    if ! command -v git &> /dev/null; then
        missing+=("git")
    fi
    
    # Проверка bash версии
    if [ "${BASH_VERSINFO[0]}" -lt 4 ]; then
        missing+=("bash 4+")
    fi
    
    if [ ${#missing[@]} -gt 0 ]; then
        log_error "Отсутствуют зависимости: ${missing[*]}"
        log_info "Установите: apt-get install jq git (для Debian/Ubuntu)"
        return 1
    fi
    
    log_success "Все зависимости установлены"
    return 0
}

# Проверка структуры директорий
check_directory_structure() {
    log_step "Проверка структуры директорий..."
    
    local dirs=(
        "$ANALYZERS_DIR"
        "$REPORTERS_DIR"
        "$REPORTS_DIR"
    )
    
    local missing=()
    
    for dir in "${dirs[@]}"; do
        if [ ! -d "$dir" ]; then
            missing+=("$dir")
        fi
    done
    
    if [ ${#missing[@]} -gt 0 ]; then
        log_error "Отсутствуют директории: ${missing[*]}"
        return 1
    fi
    
    # Проверка исполняемости скриптов
    local scripts=(
        "$ANALYZERS_DIR/git-workflow-analyzer.sh"
        "$ANALYZERS_DIR/spec-compliance-analyzer.sh"
        "$ANALYZERS_DIR/agent-interaction-analyzer.sh"
        "$ANALYZERS_DIR/logic-consistency-analyzer.sh"
        "$ANALYZERS_DIR/quality-trends-analyzer.sh"
        "$REPORTERS_DIR/generate-feedback-report.sh"
        "$REPORTERS_DIR/generate-metrics.sh"
    )
    
    local non_executable=()
    
    for script in "${scripts[@]}"; do
        if [ ! -x "$script" ]; then
            non_executable+=("$script")
        fi
    done
    
    if [ ${#non_executable[@]} -gt 0 ]; then
        log_warning "Скрипты не исполняемые. Исправление..."
        for script in "${non_executable[@]}"; do
            chmod +x "$script" 2>/dev/null || true
        done
    fi
    
    log_success "Структура директорий корректна"
    return 0
}

# Запуск анализатора
run_analyzer() {
    local name="$1"
    local cmd="$2"
    
    # Разделение пути и аргументов
    local script="${cmd%% *}"
    local args="${cmd#* }"
    if [ "$script" = "$args" ]; then
        args=""
    fi

    log_step "Запуск $name..."

    local start_time=$(date +%s)
    local result="success"
    local exit_code=0

    if [ -x "$script" ]; then
        # Запуск в тихом режиме
        if [ -n "$args" ]; then
            if ! "$script" $args -q -o "$OUTPUT_DIR" 2>&1; then
                result="failed"
                exit_code=$?
                ERRORS+=("$name: exit code $exit_code")
            fi
        else
            if ! "$script" -q -o "$OUTPUT_DIR" 2>&1; then
                result="failed"
                exit_code=$?
                ERRORS+=("$name: exit code $exit_code")
            fi
        fi
    else
        result="not_found"
        exit_code=1
        ERRORS+=("$name: script not found or not executable")
    fi

    local end_time=$(date +%s)
    local duration=$((end_time - start_time))

    ANALYZER_RESULTS+=("$name:$result:$duration")

    if [ "$result" = "success" ]; then
        log_success "$name завершен за ${duration}с"
    else
        log_error "$name: $result (${duration}с)"
    fi

    return $exit_code
}

# Запуск всех анализаторов
run_all_analyzers() {
    log_header "Запуск анализаторов"

    local failed=0

    if [ "$RUN_GIT_WORKFLOW" = true ]; then
        run_analyzer "Git Workflow" "$ANALYZERS_DIR/git-workflow-analyzer.sh" || ((failed++))
    fi

    if [ "$RUN_SPEC_COMPLIANCE" = true ]; then
        run_analyzer "Spec Compliance" "$ANALYZERS_DIR/spec-compliance-analyzer.sh" || ((failed++))
    fi

    if [ "$RUN_AGENT_INTERACTION" = true ]; then
        run_analyzer "Agent Interaction" "$ANALYZERS_DIR/agent-interaction-analyzer.sh" || ((failed++))
    fi

    if [ "$RUN_LOGIC_CONSISTENCY" = true ]; then
        run_analyzer "Logic Consistency" "$ANALYZERS_DIR/logic-consistency-analyzer.sh" || ((failed++))
    fi

    if [ "$RUN_QUALITY_TRENDS" = true ]; then
        run_analyzer "Quality Trends" "$ANALYZERS_DIR/quality-trends-analyzer.sh" || ((failed++))
    fi

    if [ "$RUN_AGENT_ANALYTICS" = true ]; then
        run_analyzer "Agent Analytics" "$PROJECT_ROOT/.qwen/analytics/agent-call-analyzer.sh" || ((failed++))
    fi

    if [ "$RUN_CHECKLIST_VALIDATION" = true ]; then
        run_analyzer "Checklist Validation" "$PROJECT_ROOT/.qwen/checklists/validate-checklist.sh --all" || ((failed++))
    fi

    # === Новые анализаторы (Error KB и Spec Analyzer) ===
    
    # Deep Spec Analyzer
    if [ "$RUN_SPEC_COMPLIANCE" = true ]; then
        run_analyzer "Deep Spec Analysis" "$PROJECT_ROOT/.qwen/analyzers/deep-spec-analyzer.sh --all" || ((failed++))
    fi
    
    # Spec Quality Metrics
    if [ "$RUN_SPEC_COMPLIANCE" = true ]; then
        run_analyzer "Spec Quality Metrics" "$PROJECT_ROOT/.qwen/analyzers/spec-quality-metrics.sh --all" || ((failed++))
    fi
    
    # Requirements Traceability
    if [ "$RUN_SPEC_COMPLIANCE" = true ]; then
        run_analyzer "Requirements Traceability" "$PROJECT_ROOT/.qwen/analyzers/requirements-traceability.sh --all" || ((failed++))
    fi
    
    # Error Knowledge Base Stats
    run_analyzer "Error KB Stats" "$PROJECT_ROOT/.qwen/knowledge-base/auto-learn.sh --stats" || ((failed++))

    return $failed
}

# Генерация отчетов
generate_reports() {
    log_header "Генерация отчетов"
    
    local failed=0
    
    if [ "$GENERATE_REPORT" = true ]; then
        log_step "Генерация Markdown отчета..."
        
        local script="$REPORTERS_DIR/generate-feedback-report.sh"
        if [ -x "$script" ]; then
            if ! "$script" -q -r "$OUTPUT_DIR" -o "$OUTPUT_DIR" 2>&1; then
                log_error "Не удалось сгенерировать Markdown отчет"
                ((failed++))
            else
                log_success "Markdown отчет сгенерирован"
            fi
        else
            log_error "Скрипт generate-feedback-report.sh не найден"
            ((failed++))
        fi
    fi
    
    if [ "$GENERATE_METRICS" = true ]; then
        log_step "Генерация метрик..."
        
        local script="$REPORTERS_DIR/generate-metrics.sh"
        if [ -x "$script" ]; then
            if ! "$script" -q -r "$OUTPUT_DIR" -o "$OUTPUT_DIR" -f "$OUTPUT_FORMAT" 2>&1; then
                log_error "Не удалось сгенерировать метрики"
                ((failed++))
            else
                log_success "Метрики сгенерированы (формат: $OUTPUT_FORMAT)"
            fi
        else
            log_error "Скрипт generate-metrics.sh не найден"
            ((failed++))
        fi
    fi
    
    return $failed
}

# Печать сводки
print_summary() {
    local total_end_time=$(date +%s)
    local total_duration=$((total_end_time - TOTAL_START_TIME))
    
    log_header "Сводка"
    
    echo ""
    echo -e "${WHITE}Результаты анализаторов:${NC}"
    echo ""
    
    local success_count=0
    local failed_count=0
    
    for result in "${ANALYZER_RESULTS[@]}"; do
        local name="${result%%:*}"
        local rest="${result#*:}"
        local status="${rest%%:*}"
        local duration="${rest#*:}"
        
        if [ "$status" = "success" ]; then
            echo -e "  ${GREEN}✓${NC} $name: ${duration}с"
            ((success_count++))
        else
            echo -e "  ${RED}✗${NC} $name: $status (${duration}с)"
            ((failed_count++))
        fi
    done
    
    echo ""
    echo -e "${WHITE}Итого:${NC}"
    echo "  Успешно: $success_count"
    echo "  Неудачно: $failed_count"
    echo "  Всего: ${#ANALYZER_RESULTS[@]}"
    echo ""
    
    if [ ${#ERRORS[@]} -gt 0 ]; then
        echo -e "${RED}Ошибки:${NC}"
        for error in "${ERRORS[@]}"; do
            echo "  - $error"
        done
        echo ""
    fi
    
    echo "  Общее время: ${total_duration}с"
    echo "  Дата: $DATE"
    echo "  Директория отчетов: $OUTPUT_DIR"
    echo ""
    
    # Список сгенерированных файлов
    echo -e "${WHITE}Сгенерированные файлы:${NC}"
    find "$OUTPUT_DIR" -name "*-$TIMESTAMP.*" -type f 2>/dev/null | while read -r file; do
        echo "  - $(basename "$file")"
    done
    echo ""
    
    # Определение общего статуса
    local overall_status="SUCCESS"
    if [ "$failed_count" -gt 0 ]; then
        if [ "$failed_count" -eq "${#ANALYZER_RESULTS[@]}" ]; then
            overall_status="FAILED"
        else
            overall_status="PARTIAL"
        fi
    fi
    
    if [ "$overall_status" = "SUCCESS" ]; then
        log_success "Статус: $overall_STATUS"
    elif [ "$overall_status" = "PARTIAL" ]; then
        log_warning "Статус: $overall_status"
    else
        log_error "Статус: $overall_status"
    fi
}

# Показать помощь
show_help() {
    cat << EOF
${WHITE}Generate All v1.0.0${NC}

Главный скрипт системы обратной связи

${WHITE}Использование:${NC}
  $(basename "$0") [OPTIONS]

${WHITE}Опции:${NC}
  -h, --help              Показать эту справку
  -v, --verbose           Подробный вывод
  -q, --quiet             Тихий режим
  -o, --output DIR        Директория для вывода (по умолчанию: ./reports)
  -f, --format FORMAT     Формат вывода: md, json, both (по умолчанию: both)
  
  --skip-git              Пропустить Git Workflow анализ
  --skip-spec             Пропустить Spec Compliance анализ
  --skip-agent            Пропустить Agent Interaction анализ
  --skip-logic            Пропустить Logic Consistency анализ
  --skip-quality          Пропустить Quality Trends анализ
  --skip-analytics        Пропустить Agent Analytics
  --skip-checklists       Пропустить Checklist Validation
  --skip-report           Пропустить генерацию отчета
  --skip-metrics          Пропустить генерацию метрик
  
  --only-analyzers        Запустить только анализаторы
  --only-reporters        Запустить только генераторы отчетов

${WHITE}Примеры:${NC}
  $(basename "$0")                                    # Полный запуск
  $(basename "$0") --skip-quality --skip-metrics      # Без quality trends и метрик
  $(basename "$0") --only-analyzers                   # Только анализаторы
  $(basename "$0") -o /tmp/reports -f json            # JSON формат в /tmp

${WHITE}Анализаторы:${NC}
  1. Git Workflow - Анализ нарушений git workflow
  2. Spec Compliance - Проверка соответствия спецификациям
  3. Agent Interaction - Анализ взаимодействия агентов
  4. Logic Consistency - Проверка логической целостности
  5. Quality Trends - Анализ трендов качества
  6. Agent Analytics - Аналитика вызовов агентов
  7. Checklist Validation - Валидация чеклистов
  8. Deep Spec Analysis - Глубокий анализ спецификаций (новый)
  9. Spec Quality Metrics - Метрики качества spec (новый)
  10. Requirements Traceability - Матрица трассировки (новый)
  11. Error KB Stats - Статистика базы знаний об ошибках (новый)

${WHITE}Error Knowledge Base:${NC}
  - error-search.sh - Поиск решений по ошибкам
  - auto-learn.sh - Автоматическое обучение на новых ошибках
  - error-index.json - Индекс ошибок

${WHITE}Выход:${NC}
  - JSON отчеты от каждого анализатора
  - Markdown сводный отчет
  - JSON/CSV метрики для дашборда
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
        -f|--format)
            OUTPUT_FORMAT="$2"
            shift 2
            ;;
        --skip-git)
            RUN_GIT_WORKFLOW=false
            shift
            ;;
        --skip-spec)
            RUN_SPEC_COMPLIANCE=false
            shift
            ;;
        --skip-agent)
            RUN_AGENT_INTERACTION=false
            shift
            ;;
        --skip-logic)
            RUN_LOGIC_CONSISTENCY=false
            shift
            ;;
        --skip-quality)
            RUN_QUALITY_TRENDS=false
            shift
            ;;
        --skip-analytics)
            RUN_AGENT_ANALYTICS=false
            shift
            ;;
        --skip-checklists)
            RUN_CHECKLIST_VALIDATION=false
            shift
            ;;
        --skip-report)
            GENERATE_REPORT=false
            shift
            ;;
        --skip-metrics)
            GENERATE_METRICS=false
            shift
            ;;
        --only-analyzers)
            GENERATE_REPORT=false
            GENERATE_METRICS=false
            shift
            ;;
        --only-reporters)
            RUN_GIT_WORKFLOW=false
            RUN_SPEC_COMPLIANCE=false
            RUN_AGENT_INTERACTION=false
            RUN_LOGIC_CONSISTENCY=false
            RUN_QUALITY_TRENDS=false
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

# Основной запуск
main() {
    if [ "$QUIET" = false ]; then
        echo ""
        log_header "Feedback System v1.0.0"
        echo ""
        echo -e "${CYAN}Проект:${NC} $PROJECT_ROOT"
        echo -e "${CYAN}Дата:${NC} $DATE"
        echo -e "${CYAN}Вывод:${NC} $OUTPUT_DIR"
        echo ""
    fi
    
    # Проверки
    if ! check_dependencies; then
        exit 1
    fi
    
    if ! check_directory_structure; then
        exit 1
    fi
    
    echo ""
    
    # Запуск анализаторов
    local analyzer_failed=0
    run_all_analyzers || analyzer_failed=$?
    
    echo ""
    
    # Генерация отчетов (только если анализаторы прошли)
    local reporters_failed=0
    if [ "$analyzer_failed" -eq 0 ] || [ "$analyzer_failed" -lt 5 ]; then
        generate_reports || reporters_failed=$?
    else
        log_warning "Пропуск генерации отчетов из-за ошибок анализаторов"
    fi
    
    echo ""
    
    # Сводка
    if [ "$QUIET" = false ]; then
        print_summary
    fi
    
    # Выход с кодом ошибки
    local total_failed=$((analyzer_failed + reporters_failed))
    if [ "$total_failed" -gt 0 ]; then
        exit 1
    fi
    
    exit 0
}

main
