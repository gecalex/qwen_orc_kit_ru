#!/bin/bash
#
# Agent Interaction Analyzer
# Назначение: Анализ взаимодействия агентов
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
NC='\033[0m' # No Color

# Конфигурация
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
OUTPUT_DIR="${OUTPUT_DIR:-$SCRIPT_DIR/../reports}"
AGENTS_DIR="${AGENTS_DIR:-$PROJECT_ROOT/.qwen/agents}"
LOGS_DIR="${LOGS_DIR:-$PROJECT_ROOT/.qwen/logs}"
TIMESTAMP=$(date +%Y-%m-%d_%H-%M-%S)

# Переменные для сбора данных
declare -a AGENT_PATTERNS=()
declare -a ANOMALIES=()
declare -a ERRORS=()
declare -a RECOMMENDATIONS=()

# Метрики
TOTAL_AGENTS=0
ACTIVE_AGENTS=0
ORCHESTRATORS=0
WORKERS=0
SKILLS=0
TOTAL_CALLS=0
REPEATED_CALLS=0
HANGING_CALLS=0
AGENT_ERRORS=0
AVG_RESPONSE_TIME=0
TOTAL_TOKENS=0

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

# Анализ структуры агентов
analyze_agent_structure() {
    log_info "Анализ структуры агентов..."

    if [ ! -d "$AGENTS_DIR" ]; then
        log_warning "Директория агентов не найдена: $AGENTS_DIR"
        ANOMALIES+=("Директория агентов отсутствует")
        return 0
    fi
    
    # Подсчет агентов по типам
    TOTAL_AGENTS=$(find "$AGENTS_DIR" -name "*.md" -type f 2>/dev/null | wc -l)
    
    # Поиск оркестраторов
    ORCHESTRATORS=$(grep -rl "оркестратор\|orchestrator" "$AGENTS_DIR" 2>/dev/null | wc -l || echo "0")
    
    # Поиск воркеров
    WORKERS=$(grep -rl "воркер\|worker\|исполнитель" "$AGENTS_DIR" 2>/dev/null | wc -l || echo "0")
    
    # Поиск навыков (skills)
    SKILLS=$(find "$AGENTS_DIR" -name "*.md" -type f -exec grep -l "навык\|skill" {} \; 2>/dev/null | wc -l || echo "0")
    
    log_success "Всего агентов: $TOTAL_AGENTS"
    log_info "Оркестраторы: $ORCHESTRATORS, Воркеры: $WORKERS, Навыки: $SKILLS"
    
    # Проверка на наличие активных агентов
    ACTIVE_AGENTS=0
    while IFS= read -r agent_file; do
        if [ -n "$agent_file" ]; then
            local content
            content=$(cat "$agent_file" 2>/dev/null || echo "")
            if [ -n "$content" ] && [ ${#content} -gt 500 ]; then
                ((ACTIVE_AGENTS++)) || true
            fi
        fi
    done < <(find "$AGENTS_DIR" -name "*.md" -type f 2>/dev/null)
    
    if [ "$ACTIVE_AGENTS" -lt "$TOTAL_AGENTS" ]; then
        local inactive=$((TOTAL_AGENTS - ACTIVE_AGENTS))
        ANOMALIES+=("$inactive неактивных агентов (пустые или короткие файлы)")
    fi
}

# Анализ паттернов вызовов агентов
analyze_call_patterns() {
    log_info "Анализ паттернов вызовов..."
    
    # Поиск файлов сессий/логов
    local session_files=0
    local logs_found=0
    
    if [ -d "$LOGS_DIR" ]; then
        logs_found=$(find "$LOGS_DIR" -name "*.json" -o -name "*.log" 2>/dev/null | wc -l || echo "0")
    fi
    
    # Поиск в истории git
    local git_commits_with_agents
    git_commits_with_agents=$(git log --all --oneline --grep="agent\|агент" 2>/dev/null | wc -l || echo "0")
    
    if [ "$logs_found" -eq 0 ] && [ "$git_commits_with_agents" -eq 0 ]; then
        log_warning "Логи взаимодействий не найдены"
        RECOMMENDATIONS+=("Настройте логирование взаимодействий агентов")
    else
        TOTAL_CALLS=$((logs_found + git_commits_with_agents))
        log_info "Найдено записей о вызовах: $TOTAL_CALLS"
    fi
    
    # Анализ частоты вызовов по агентам
    declare -A agent_calls
    
    if [ -d "$AGENTS_DIR" ]; then
        while IFS= read -r agent_file; do
            if [ -n "$agent_file" ]; then
                local agent_name
                agent_name=$(basename "$agent_file" .md)
                
                # Поиск упоминаний агента в коде
                local mentions
                mentions=$(grep -r "$agent_name" "$PROJECT_ROOT" --include="*.sh" --include="*.md" --include="*.json" 2>/dev/null | wc -l || echo "0")
                
                if [ "$mentions" -gt 10 ]; then
                    AGENT_PATTERNS+=("Агент $agent_name: частый вызов ($mentions упоминаний)")
                elif [ "$mentions" -eq 0 ] && [ "$agent_name" != "README" ]; then
                    ANOMALIES+=("Агент $agent_name: нет упоминаний в коде (возможно неиспользуемый)")
                fi
            fi
        done < <(find "$AGENTS_DIR" -name "*.md" -type f 2>/dev/null)
    fi
}

# Поиск аномалий (зависания, повторные вызовы)
detect_anomalies() {
    log_info "Поиск аномалий..."
    
    # Проверка на циклические зависимости
    if [ -d "$AGENTS_DIR" ]; then
        while IFS= read -r agent_file; do
            if [ -n "$agent_file" ]; then
                local agent_name
                agent_name=$(basename "$agent_file" .md)
                local content
                content=$(cat "$agent_file" 2>/dev/null || echo "")
                
                # Поиск самореференсов
                if echo "$content" | grep -qi "вызывает.*$agent_name\|calls.*$agent_name"; then
                    ANOMALIES+=("Агент $agent_name: возможная циклическая зависимость")
                    ((HANGING_CALLS++)) || true
                fi
                
                # Поиск множественных вызовов одного агента
                local next_agent_mentions
                next_agent_mentions=$(echo "$content" | grep -oE "nextAgent[\"']?\s*[:=]\s*[\"']?[a-z_]+" 2>/dev/null | wc -l | tr -d '[:space:]')
                next_agent_mentions=${next_agent_mentions:-0}

                if [ "$next_agent_mentions" -gt 5 ]; then
                    ((REPEATED_CALLS++)) || true
                fi
            fi
        done < <(find "$AGENTS_DIR" -name "*.md" -type f 2>/dev/null)
    fi
    
    # Проверка логов на ошибки
    if [ -d "$LOGS_DIR" ]; then
        local error_count
        error_count=$(grep -ri "error\|ошибка\|failed\|неудачно" "$LOGS_DIR" 2>/dev/null | wc -l | tr -d '[:space:]')
        error_count=${error_count:-0}

        if [ "$error_count" -gt 0 ]; then
            AGENT_ERRORS=$error_count
            ERRORS+=("Найдено ошибок в логах: $error_count")
        fi
    fi
    
    # Проверка на длительные операции
    if [ -d "$LOGS_DIR" ]; then
        while IFS= read -r log_file; do
            if [ -n "$log_file" ]; then
                # Поиск операций дольше 60 секунд
                local long_ops
                long_ops=$(grep -oE "duration[\"']?\s*[:=]\s*[\"']?[0-9]+" "$log_file" 2>/dev/null | awk -F'[:=]' '{if ($2 > 60000) print}' | wc -l || echo "0")
                
                if [ "$long_ops" -gt 0 ]; then
                    ANOMALIES+=("Файл $(basename "$log_file"): $long_ops операций > 60 сек")
                fi
            fi
        done < <(find "$LOGS_DIR" -name "*.json" 2>/dev/null)
    fi
    
    if [ "$REPEATED_CALLS" -gt 0 ]; then
        RECOMMENDATIONS+=("Проверьте $REPEATED_CALLS агентов на предмет избыточных вызовов")
    fi
    
    if [ "$HANGING_CALLS" -gt 0 ]; then
        RECOMMENDATIONS+=("Устраните $HANGING_CALLS потенциальных циклических зависимостей")
    fi
}

# Анализ эффективности (время, токены)
analyze_efficiency() {
    log_info "Анализ эффективности..."
    
    local total_time=0
    local time_count=0
    local total_tokens_found=0
    
    # Анализ времени выполнения из логов
    if [ -d "$LOGS_DIR" ]; then
        while IFS= read -r log_file; do
            if [ -n "$log_file" ]; then
                # Извлечение времени выполнения
                local times
                times=$(grep -oE "duration[\"']?\s*[:=]\s*[\"']?[0-9]+" "$log_file" 2>/dev/null | grep -oE "[0-9]+" || echo "")
                
                for time in $times; do
                    total_time=$((total_time + time))
                    ((time_count++)) || true
                done
                
                # Извлечение токенов
                local tokens
                tokens=$(grep -oE "tokens[\"']?\s*[:=]\s*[\"']?[0-9]+" "$log_file" 2>/dev/null | grep -oE "[0-9]+" || echo "")
                
                for token in $tokens; do
                    total_tokens_found=$((total_tokens_found + token))
                done
            fi
        done < <(find "$LOGS_DIR" -name "*.json" 2>/dev/null)
    fi
    
    # Расчет среднего времени
    if [ "$time_count" -gt 0 ]; then
        AVG_RESPONSE_TIME=$((total_time / time_count))
        
        if [ "$AVG_RESPONSE_TIME" -gt 30000 ]; then
            ANOMALIES+=("Среднее время ответа высокое: $((AVG_RESPONSE_TIME / 1000)) сек")
            RECOMMENDATIONS+=("Оптимизируйте медленные операции агентов")
        fi
    fi
    
    TOTAL_TOKENS=$total_tokens_found
    
    if [ "$TOTAL_TOKENS" -gt 0 ]; then
        log_info "Всего токенов: $TOTAL_TOKENS"
    fi
}

# Анализ ошибок агентов
analyze_agent_errors() {
    log_info "Анализ ошибок агентов..."
    
    # Поиск файлов с ошибками
    local error_files=0
    
    if [ -d "$LOGS_DIR" ]; then
        error_files=$(find "$LOGS_DIR" -name "*error*" -o -name "*fail*" 2>/dev/null | wc -l || echo "0")
    fi
    
    # Поиск в агентах упоминаний обработчиков ошибок
    local error_handlers=0
    if [ -d "$AGENTS_DIR" ]; then
        error_handlers=$(grep -rl "error\|ошибка\|exception\|catch" "$AGENTS_DIR" 2>/dev/null | wc -l || echo "0")
    fi
    
    if [ "$error_files" -gt 0 ] && [ "$error_handlers" -eq 0 ]; then
        RECOMMENDATIONS+=("Добавьте обработку ошибок в агенты (найдено $error_files файлов с ошибками)")
    fi
    
    # Проверка на отсутствие fallback агентов
    local fallback_count=0
    if [ -d "$AGENTS_DIR" ]; then
        fallback_count=$(grep -rl "fallback\|резервный\|альтернативный" "$AGENTS_DIR" 2>/dev/null | wc -l || echo "0")
    fi
    
    if [ "$TOTAL_AGENTS" -gt 5 ] && [ "$fallback_count" -eq 0 ]; then
        RECOMMENDATIONS+=("Рассмотрите добавление fallback механизмов для критических агентов")
    fi
}

# Расчет общего score
calculate_score() {
    local score=100
    
    # Штрафы за аномалии
    score=$((score - ${#ANOMALIES[@]} * 5))
    score=$((score - ${#ERRORS[@]} * 10))
    
    # Штрафы за неэффективность
    if [ "$AVG_RESPONSE_TIME" -gt 30000 ]; then
        score=$((score - 10))
    fi
    
    if [ "$HANGING_CALLS" -gt 0 ]; then
        score=$((score - HANGING_CALLS * 5))
    fi
    
    # Бонусы за хорошую структуру
    if [ "$ORCHESTRATORS" -gt 0 ] && [ "$WORKERS" -gt 0 ]; then
        score=$((score + 5))
    fi
    
    if [ "$ACTIVE_AGENTS" -eq "$TOTAL_AGENTS" ] && [ "$TOTAL_AGENTS" -gt 0 ]; then
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
    score=$(calculate_score)
    
    # Формирование массивов JSON
    local patterns_json="[]"
    local anomalies_json="[]"
    local errors_json="[]"
    local recommendations_json="[]"
    
    if [ ${#AGENT_PATTERNS[@]} -gt 0 ]; then
        patterns_json=$(printf '%s\n' "${AGENT_PATTERNS[@]}" | jq -R . | jq -s .)
    fi
    
    if [ ${#ANOMALIES[@]} -gt 0 ]; then
        anomalies_json=$(printf '%s\n' "${ANOMALIES[@]}" | jq -R . | jq -s .)
    fi
    
    if [ ${#ERRORS[@]} -gt 0 ]; then
        errors_json=$(printf '%s\n' "${ERRORS[@]}" | jq -R . | jq -s .)
    fi
    
    if [ ${#RECOMMENDATIONS[@]} -gt 0 ]; then
        recommendations_json=$(printf '%s\n' "${RECOMMENDATIONS[@]}" | jq -R . | jq -s .)
    fi
    
    # Создание JSON файла
    cat > "$OUTPUT_DIR/agent-interaction-analysis-$TIMESTAMP.json" << EOF
{
  "timestamp": "$TIMESTAMP",
  "status": "completed",
  "analyzer": "agent-interaction-analyzer",
  "version": "1.0.0",
  "project_root": "$PROJECT_ROOT",
  "agents_directory": "$AGENTS_DIR",
  "patterns": $patterns_json,
  "anomalies": $anomalies_json,
  "errors": $errors_json,
  "recommendations": $recommendations_json,
  "metrics": {
    "total_agents": $TOTAL_AGENTS,
    "active_agents": $ACTIVE_AGENTS,
    "orchestrators": $ORCHESTRATORS,
    "workers": $WORKERS,
    "skills": $SKILLS,
    "total_calls": $TOTAL_CALLS,
    "repeated_calls": $REPEATED_CALLS,
    "hanging_calls": $HANGING_CALLS,
    "agent_errors": $AGENT_ERRORS,
    "avg_response_time_ms": $AVG_RESPONSE_TIME,
    "total_tokens": $TOTAL_TOKENS
  },
  "score": $score,
  "grade": "$(if [ $score -ge 90 ]; then echo "A"; elif [ $score -ge 80 ]; then echo "B"; elif [ $score -ge 70 ]; then echo "C"; elif [ $score -ge 60 ]; then echo "D"; else echo "F"; fi)"
}
EOF
    
    log_success "Отчет сохранен: $OUTPUT_DIR/agent-interaction-analysis-$TIMESTAMP.json"
}

# Показать помощь
show_help() {
    cat << EOF
Agent Interaction Analyzer v1.0.0

Назначение: Анализ взаимодействия агентов

Использование:
  $(basename "$0") [OPTIONS]

Опции:
  -h, --help          Показать эту справку
  -v, --verbose       Подробный вывод
  -q, --quiet         Тихий режим (только JSON)
  -o, --output        Директория для вывода (по умолчанию: ../reports)
  -a, --agents-dir    Директория агентов (по умолчанию: .qwen/agents)
  -l, --logs-dir      Директория логов (по умолчанию: .qwen/logs)

Примеры:
  $(basename "$0")                              # Запуск с настройками по умолчанию
  $(basename "$0") -a /path/to/agents           # Указать директорию агентов
  $(basename "$0") -q                           # Тихий режим

Проверки:
  1. Паттерны вызовов агентов
  2. Аномалии (зависания, повторные вызовы)
  3. Эффективность (время, токены)
  4. Ошибки агентов

Выход:
  JSON с метриками и паттернами
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
        -a|--agents-dir)
            AGENTS_DIR="$2"
            shift 2
            ;;
        -l|--logs-dir)
            LOGS_DIR="$2"
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
        echo "  Agent Interaction Analyzer v1.0.0"
        echo "========================================"
        echo ""
    fi
    
    analyze_agent_structure
    analyze_call_patterns
    detect_anomalies
    analyze_efficiency
    analyze_agent_errors
    
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
        echo "Всего агентов: $TOTAL_AGENTS (Активных: $ACTIVE_AGENTS)"
        echo "Оркестраторы: $ORCHESTRATORS, Воркеры: $WORKERS"
        echo ""
        echo "Паттерны: ${#AGENT_PATTERNS[@]}"
        echo "Аномалии: ${#ANOMALIES[@]}"
        echo "Ошибки: ${#ERRORS[@]}"
        echo "Рекомендации: ${#RECOMMENDATIONS[@]}"
    fi
}

main
