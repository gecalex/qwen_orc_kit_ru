#!/bin/bash
#
# Detect Anomalies - Обнаружение аномалий в работе агентов
# Назначение: Выявление зависаний, повторных вызовов, циклических вызовов, необычных паттернов
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
ANALYTICS_DIR="$SCRIPT_DIR"
REPORTS_DIR="$SCRIPT_DIR/reports"
LOGS_DIR="$PROJECT_ROOT/.qwen/logs"
TIMESTAMP=$(date +%Y-%m-%d_%H-%M-%S)
DATE=$(date +%Y-%m-%d)

# Пороги для обнаружения аномалий
TIMEOUT_THRESHOLD=300        # 5 минут в секундах
REPEAT_CALLS_THRESHOLD=3     # Количество повторных вызовов
CYCLE_DETECTION_WINDOW=10    # Окно для обнаружения циклов
UNUSUAL_PATTERN_STDDEV=2     # Стандартное отклонение для необычных паттернов

# Флаги
VERBOSE=false
QUIET=false
OUTPUT_DIR="$REPORTS_DIR"
LOG_FILE="$LOGS_DIR/agent-calls.log"

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
${WHITE}Detect Anomalies v1.0.0${NC}

Обнаружение аномалий в работе агентов

${WHITE}Использование:${NC}
  $(basename "$0") [OPTIONS]

${WHITE}Опции:${NC}
  -h, --help              Показать эту справку
  -v, --verbose           Подробный вывод
  -q, --quiet             Тихий режим (только JSON)
  -o, --output DIR        Директория для вывода
  -l, --log FILE          Файл логов

${WHITE}Типы обнаруживаемых аномалий:${NC}
  🚨 Зависания (timeout > 5 мин)
  🚨 Повторные вызовы (> 3 раз)
  🚨 Циклические вызовы (A → B → A)
  🚨 Необычные паттерны

${WHITE}Примеры:${NC}
  $(basename "$0")                                    # Полный анализ
  $(basename "$0") -v                                 # Подробный вывод
  $(basename "$0") -o /tmp/anomalies                  # Вывод в /tmp

${WHITE}Выход:${NC}
  - JSON с аномалиями и рекомендациями
  - Markdown отчет (в подробном режиме)
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

# Инициализация логов
initialize_logs() {
    if [ ! -f "$LOG_FILE" ] || [ ! -s "$LOG_FILE" ]; then
        log_warning "Файл логов не найден. Создание тестовых данных..."
        mkdir -p "$LOGS_DIR"
        
        # Запуск анализатора для создания логов
        local analyzer_script="$ANALYTICS_DIR/agent-call-analyzer.sh"
        if [ -x "$analyzer_script" ]; then
            "$analyzer_script" -q -o "$OUTPUT_DIR" -l "$LOG_FILE" > /dev/null 2>&1
            log_success "Тестовые данные созданы"
        else
            log_error "agent-call-analyzer.sh не найден"
            return 1
        fi
    fi
}

# Обнаружение зависаний (timeout)
detect_timeouts() {
    log_step "Обнаружение зависаний (timeout > ${TIMEOUT_THRESHOLD}с)..."

    declare -ga TIMEOUT_ANOMALIES=()

    while IFS='|' read -r timestamp agent status task result rest; do
        if [[ "$status" == "completed" || "$status" == "failed" ]]; then
            # Извлечение времени
            if [[ "$rest" =~ ([0-9]+)s ]]; then
                local duration=${BASH_REMATCH[1]}
                if [ "$duration" -gt "$TIMEOUT_THRESHOLD" ]; then
                    TIMEOUT_ANOMALIES+=("$agent|$task|$duration|$timestamp")
                fi
            fi
        fi
    done < "$LOG_FILE"

    log_info "Найдено зависаний: ${#TIMEOUT_ANOMALIES[@]}"
}

# Обнаружение повторных вызовов
detect_repeat_calls() {
    log_step "Обнаружение повторных вызовов (> ${REPEAT_CALLS_THRESHOLD} раз)..."
    
    declare -ga REPEAT_ANOMALIES=()
    declare -A TASK_RETRIES
    
    # Подсчет повторных вызовов по задачам
    while IFS='|' read -r timestamp agent status task result rest; do
        if [[ "$status" == "failed" || "$status" == "timeout" ]]; then
            local key="$agent|$task"
            TASK_RETRIES["$key"]=$((${TASK_RETRIES["$key"]:-0} + 1))
        fi
    done < "$LOG_FILE"
    
    # Фильтрация по порогу
    for key in "${!TASK_RETRIES[@]}"; do
        local count=${TASK_RETRIES[$key]}
        if [ "$count" -gt "$REPEAT_CALLS_THRESHOLD" ]; then
            local agent=$(echo "$key" | cut -d'|' -f1)
            local task=$(echo "$key" | cut -d'|' -f2)
            REPEAT_ANOMALIES+=("$agent|$task|$count")
        fi
    done
    
    log_info "Найдено повторных вызовов: ${#REPEAT_ANOMALIES[@]}"
}

# Обнаружение циклических вызовов
detect_cycle_calls() {
    log_step "Обнаружение циклических вызовов..."
    
    declare -ga CYCLE_ANOMALIES=()
    declare -a CALL_SEQUENCE=()
    
    # Построение последовательности вызовов
    while IFS='|' read -r timestamp agent status task result rest; do
        if [[ "$status" == "started" ]]; then
            CALL_SEQUENCE+=("$agent")
        fi
    done < "$LOG_FILE"
    
    # Поиск циклов в последовательности
    local seq_len=${#CALL_SEQUENCE[@]}
    for ((i=0; i<seq_len-CYCLE_DETECTION_WINDOW; i++)); do
        local agent_a="${CALL_SEQUENCE[$i]}"
        
        # Поиск возврата к тому же агенту в окне
        for ((j=i+2; j<i+CYCLE_DETECTION_WINDOW && j<seq_len; j++)); do
            if [[ "${CALL_SEQUENCE[$j]}" == "$agent_a" ]]; then
                # Проверка на простой цикл A → B → A
                if [[ $((j - i)) -eq 2 ]]; then
                    local agent_b="${CALL_SEQUENCE[$((i+1))]}"
                    local cycle_key="$agent_a|$agent_b"
                    
                    # Проверка на дубликаты
                    local found=false
                    for existing in "${CYCLE_ANOMALIES[@]}"; do
                        if [[ "$existing" == "$cycle_key" ]]; then
                            found=true
                            break
                        fi
                    done
                    
                    if [ "$found" = false ]; then
                        CYCLE_ANOMALIES+=("$cycle_key")
                    fi
                fi
            fi
        done
    done
    
    log_info "Найдено циклов: ${#CYCLE_ANOMALIES[@]}"
}

# Обнаружение необычных паттернов
detect_unusual_patterns() {
    log_step "Обнаружение необычных паттернов..."
    
    declare -ga UNUSUAL_ANOMALIES=()
    declare -A AGENT_CALL_COUNTS
    declare -A AGENT_HOURLY_COUNTS
    
    # Сбор статистики по агентам по часам
    while IFS='|' read -r timestamp agent status task result rest; do
        if [[ "$status" == "started" ]]; then
            local hour=$(echo "$timestamp" | cut -d'T' -f2 | cut -d':' -f1)
            local key="$agent|$hour"
            AGENT_HOURLY_COUNTS["$key"]=$((${AGENT_HOURLY_COUNTS["$key"]:-0} + 1))
            AGENT_CALL_COUNTS["$agent"]=$((${AGENT_CALL_COUNTS["$agent"]:-0} + 1))
        fi
    done < "$LOG_FILE"
    
    # Расчет среднего и отклонения для каждого агента
    for agent in "${!AGENT_CALL_COUNTS[@]}"; do
        local total=${AGENT_CALL_COUNTS[$agent]}
        local hours_with_calls=0
        local sum=0
        
        for h in $(seq -w 0 23); do
            local key="$agent|$h"
            local count=${AGENT_HOURLY_COUNTS["$key"]:-0}
            if [ "$count" -gt 0 ]; then
                hours_with_calls=$((hours_with_calls + 1))
                sum=$((sum + count))
            fi
        done
        
        if [ "$hours_with_calls" -gt 1 ]; then
            local avg=$((sum / hours_with_calls))
            local threshold=$((avg * 3))  # 3x от среднего считается аномалией
            
            for h in $(seq -w 0 23); do
                local key="$agent|$h"
                local count=${AGENT_HOURLY_COUNTS["$key"]:-0}
                if [ "$count" -gt "$threshold" ] && [ "$count" -gt 5 ]; then
                    UNUSUAL_ANOMALIES+=("$agent|$h|$count|spike")
                fi
            done
        fi
    done
    
    log_info "Найдено необычных паттернов: ${#UNUSUAL_ANOMALIES[@]}"
}

# Генерация рекомендаций для аномалий
generate_recommendations() {
    local anomaly_type="$1"
    local agent="$2"
    local details="$3"
    
    case "$anomaly_type" in
        timeout)
            echo "Увеличить timeout для агента или оптимизировать выполнение"
            ;;
        repeat_calls)
            echo "Исследовать причину повторных неудач, добавить обработку ошибок"
            ;;
        cycle)
            echo "Пересмотреть архитектуру взаимодействия агентов"
            ;;
        unusual_pattern)
            echo "Проанализировать нагрузку, рассмотреть балансировку"
            ;;
        *)
            echo "Требуется дополнительный анализ"
            ;;
    esac
}

# Генерация JSON отчета
generate_json_report() {
    log_step "Генерация JSON отчета..."
    
    local json_file="$OUTPUT_DIR/anomaly-detection-$TIMESTAMP.json"
    
    # Построение JSON для timeout аномалий
    local timeout_json="["
    local first=true
    for anomaly in "${TIMEOUT_ANOMALIES[@]}"; do
        if [ "$first" = false ]; then
            timeout_json+=","
        fi
        first=false
        
        IFS='|' read -r agent task duration timestamp <<< "$anomaly"
        timeout_json+="
    {
      \"type\": \"timeout\",
      \"severity\": \"high\",
      \"agent\": \"$agent\",
      \"task\": \"$task\",
      \"duration_seconds\": $duration,
      \"timestamp\": \"$timestamp\",
      \"recommendation\": \"$(generate_recommendations 'timeout' "$agent" "$duration")\"
    }"
    done
    timeout_json+="
  ]"
    
    # JSON для repeat аномалий
    local repeat_json="["
    first=true
    for anomaly in "${REPEAT_ANOMALIES[@]}"; do
        if [ "$first" = false ]; then
            repeat_json+=","
        fi
        first=false
        
        IFS='|' read -r agent task count <<< "$anomaly"
        repeat_json+="
    {
      \"type\": \"repeat_calls\",
      \"severity\": \"medium\",
      \"agent\": \"$agent\",
      \"task\": \"$task\",
      \"retry_count\": $count,
      \"recommendation\": \"$(generate_recommendations 'repeat_calls' "$agent" "$count")\"
    }"
    done
    repeat_json+="
  ]"
    
    # JSON для cycle аномалий
    local cycle_json="["
    first=true
    for anomaly in "${CYCLE_ANOMALIES[@]}"; do
        if [ "$first" = false ]; then
            cycle_json+=","
        fi
        first=false
        
        IFS='|' read -r agent_a agent_b <<< "$anomaly"
        cycle_json+="
    {
      \"type\": \"cyclic_calls\",
      \"severity\": \"high\",
      \"agents\": [\"$agent_a\", \"$agent_b\"],
      \"pattern\": \"$agent_a → $agent_b → $agent_a\",
      \"recommendation\": \"$(generate_recommendations 'cycle' \"$agent_a\" \"\")\"
    }"
    done
    cycle_json+="
  ]"
    
    # JSON для unusual pattern аномалий
    local unusual_json="["
    first=true
    for anomaly in "${UNUSUAL_ANOMALIES[@]}"; do
        if [ "$first" = false ]; then
            unusual_json+=","
        fi
        first=false
        
        IFS='|' read -r agent hour count pattern <<< "$anomaly"
        unusual_json+="
    {
      \"type\": \"unusual_pattern\",
      \"severity\": \"low\",
      \"agent\": \"$agent\",
      \"hour\": \"$hour:00\",
      \"call_count\": $count,
      \"pattern\": \"$pattern\",
      \"recommendation\": \"$(generate_recommendations 'unusual_pattern' "$agent" "$hour")\"
    }"
    done
    unusual_json+="
  ]"
    
    # Подсчет общего количества
    local total_anomalies=$((${#TIMEOUT_ANOMALIES[@]} + ${#REPEAT_ANOMALIES[@]} + ${#CYCLE_ANOMALIES[@]} + ${#UNUSUAL_ANOMALIES[@]}))
    
    # Определение общего уровня серьезности
    local overall_severity="low"
    if [ "${#TIMEOUT_ANOMALIES[@]}" -gt 0 ] || [ "${#CYCLE_ANOMALIES[@]}" -gt 0 ]; then
        overall_severity="high"
    elif [ "${#REPEAT_ANOMALIES[@]}" -gt 0 ]; then
        overall_severity="medium"
    fi
    
    cat > "$json_file" << EOF
{
  "timestamp": "$TIMESTAMP",
  "date": "$DATE",
  "log_file": "$LOG_FILE",
  "summary": {
    "total_anomalies": $total_anomalies,
    "timeout_count": ${#TIMEOUT_ANOMALIES[@]},
    "repeat_calls_count": ${#REPEAT_ANOMALIES[@]},
    "cyclic_calls_count": ${#CYCLE_ANOMALIES[@]},
    "unusual_patterns_count": ${#UNUSUAL_ANOMALIES[@]},
    "overall_severity": "$overall_severity"
  },
  "thresholds": {
    "timeout_seconds": $TIMEOUT_THRESHOLD,
    "repeat_calls": $REPEAT_CALLS_THRESHOLD,
    "cycle_detection_window": $CYCLE_DETECTION_WINDOW
  },
  "anomalies": {
    "timeouts": $timeout_json,
    "repeat_calls": $repeat_json,
    "cyclic_calls": $cycle_json,
    "unusual_patterns": $unusual_json
  }
}
EOF
    
    log_success "JSON отчет: $json_file"
    echo "$json_file"
}

# Генерация Markdown отчета
generate_markdown_report() {
    log_step "Генерация Markdown отчета..."
    
    local md_file="$OUTPUT_DIR/anomaly-detection-$TIMESTAMP.md"
    local total_anomalies=$((${#TIMEOUT_ANOMALIES[@]} + ${#REPEAT_ANOMALIES[@]} + ${#CYCLE_ANOMALIES[@]} + ${#UNUSUAL_ANOMALIES[@]}))
    
    # Определение статуса
    local status_emoji="✅"
    local status_text="Аномалий не обнаружено"
    if [ "$total_anomalies" -gt 0 ]; then
        status_emoji="⚠️"
        status_text="Обнаружено аномалий: $total_anomalies"
    fi
    
    cat > "$md_file" << EOF
# Anomaly Detection Report

**Дата**: $DATE  
**Время генерации**: $TIMESTAMP  
**Файл логов**: $LOG_FILE  
**Статус**: $status_emoji $status_text

---

## Summary

| Тип аномалии | Количество |
|--------------|------------|
| 🚨 Зависания (timeout) | ${#TIMEOUT_ANOMALIES[@]} |
| ⚠️ Повторные вызовы | ${#REPEAT_ANOMALIES[@]} |
| 🔄 Циклические вызовы | ${#CYCLE_ANOMALIES[@]} |
| 📊 Необычные паттерны | ${#UNUSUAL_ANOMALIES[@]} |
| **Всего** | **$total_anomalies** |

---

## Thresholds

| Параметр | Значение |
|----------|----------|
| Timeout порог | ${TIMEOUT_THRESHOLD}с (5 мин) |
| Повторные вызовы | > ${REPEAT_CALLS_THRESHOLD} раз |
| Окно детекции циклов | ${CYCLE_DETECTION_WINDOW} вызовов |

---

## 🚨 Timeout Аномалии

EOF

    if [ ${#TIMEOUT_ANOMALIES[@]} -eq 0 ]; then
        echo "✅ Зависаний не обнаружено" >> "$md_file"
    else
        echo "| Агент | Задача | Длительность | Время |" >> "$md_file"
        echo "|-------|--------|--------------|-------|" >> "$md_file"
        for anomaly in "${TIMEOUT_ANOMALIES[@]}"; do
            IFS='|' read -r agent task duration timestamp <<< "$anomaly"
            echo "| $agent | $task | ${duration}с | $timestamp |" >> "$md_file"
        done
    fi
    
    cat >> "$md_file" << EOF

---

## ⚠️ Повторные вызовы

EOF

    if [ ${#REPEAT_ANOMALIES[@]} -eq 0 ]; then
        echo "✅ Повторных вызовов не обнаружено" >> "$md_file"
    else
        echo "| Агент | Задача | Количество |" >> "$md_file"
        echo "|-------|--------|------------|" >> "$md_file"
        for anomaly in "${REPEAT_ANOMALIES[@]}"; do
            IFS='|' read -r agent task count <<< "$anomaly"
            echo "| $agent | $task | $count |" >> "$md_file"
        done
    fi
    
    cat >> "$md_file" << EOF

---

## 🔄 Циклические вызовы

EOF

    if [ ${#CYCLE_ANOMALIES[@]} -eq 0 ]; then
        echo "✅ Циклических вызовов не обнаружено" >> "$md_file"
    else
        echo "| Паттерн | Агенты |" >> "$md_file"
        echo "|---------|--------|" >> "$md_file"
        for anomaly in "${CYCLE_ANOMALIES[@]}"; do
            IFS='|' read -r agent_a agent_b <<< "$anomaly"
            echo "| $agent_a → $agent_b → $agent_a | $agent_a, $agent_b |" >> "$md_file"
        done
    fi
    
    cat >> "$md_file" << EOF

---

## 📊 Необычные паттерны

EOF

    if [ ${#UNUSUAL_ANOMALIES[@]} -eq 0 ]; then
        echo "✅ Необычных паттернов не обнаружено" >> "$md_file"
    else
        echo "| Агент | Час | Вызовов | Тип |" >> "$md_file"
        echo "|-------|-----|---------|-----|" >> "$md_file"
        for anomaly in "${UNUSUAL_ANOMALIES[@]}"; do
            IFS='|' read -r agent hour count pattern <<< "$anomaly"
            echo "| $agent | ${hour}:00 | $count | $pattern |" >> "$md_file"
        done
    fi
    
    cat >> "$md_file" << EOF

---

## Recommendations

EOF

    local has_recommendations=false
    
    if [ ${#TIMEOUT_ANOMALIES[@]} -gt 0 ]; then
        has_recommendations=true
        cat >> "$md_file" << EOF
### Timeout аномалии
- Увеличить timeout для проблемных агентов
- Добавить прогресс-логирование для долгих операций
- Рассмотреть разделение задач на подзадачи
- Реализовать graceful shutdown

EOF
    fi
    
    if [ ${#REPEAT_ANOMALIES[@]} -gt 0 ]; then
        has_recommendations=true
        cat >> "$md_file" << EOF
### Повторные вызовы
- Исследовать корневую причину неудач
- Добавить лучшую обработку ошибок
- Реализовать exponential backoff
- Рассмотреть fallback агенты

EOF
    fi
    
    if [ ${#CYCLE_ANOMALIES[@]} -gt 0 ]; then
        has_recommendations=true
        cat >> "$md_file" << EOF
### Циклические вызовы
- Пересмотреть архитектуру взаимодействия
- Добавить детекцию циклов в runtime
- Реализовать ограничение глубины вызовов
- Использовать кэширование результатов

EOF
    fi
    
    if [ ${#UNUSUAL_ANOMALIES[@]} -gt 0 ]; then
        has_recommendations=true
        cat >> "$md_file" << EOF
### Необычные паттерны
- Проанализировать распределение нагрузки
- Рассмотреть балансировку между агентами
- Настроить алерты на аномальную активность
- Исследовать внешние факторы влияния

EOF
    fi
    
    if [ "$has_recommendations" = false ]; then
        echo "✅ Система работает оптимально. Рекомендаций нет." >> "$md_file"
    fi
    
    cat >> "$md_file" << EOF

---

*Report сгенерирован Qwen Orchestrator Kit - Anomaly Detection v1.0.0*
EOF
    
    log_success "Markdown отчет: $md_file"
    echo "$md_file"
}

# Вывод краткой сводки
print_summary() {
    local total_anomalies=$((${#TIMEOUT_ANOMALIES[@]} + ${#REPEAT_ANOMALIES[@]} + ${#CYCLE_ANOMALIES[@]} + ${#UNUSUAL_ANOMALIES[@]}))
    
    echo ""
    log_header "Anomaly Detection Summary"
    echo ""
    
    if [ "$total_anomalies" -eq 0 ]; then
        echo -e "${GREEN}✅ Аномалий не обнаружено${NC}"
    else
        echo -e "${YELLOW}⚠️ Обнаружено аномалий: $total_anomalies${NC}"
        echo ""
        
        if [ ${#TIMEOUT_ANOMALIES[@]} -gt 0 ]; then
            echo -e "  ${RED}🚨 Зависания:${NC} ${#TIMEOUT_ANOMALIES[@]}"
        fi
        if [ ${#REPEAT_ANOMALIES[@]} -gt 0 ]; then
            echo -e "  ${YELLOW}⚠️ Повторные вызовы:${NC} ${#REPEAT_ANOMALIES[@]}"
        fi
        if [ ${#CYCLE_ANOMALIES[@]} -gt 0 ]; then
            echo -e "  ${MAGENTA}🔄 Циклические вызовы:${NC} ${#CYCLE_ANOMALIES[@]}"
        fi
        if [ ${#UNUSUAL_ANOMALIES[@]} -gt 0 ]; then
            echo -e "  ${BLUE}📊 Необычные паттерны:${NC} ${#UNUSUAL_ANOMALIES[@]}"
        fi
    fi
    
    echo ""
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
            -l|--log)
                LOG_FILE="$2"
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
    
    if [ "$QUIET" = false ]; then
        echo ""
        log_header "Detect Anomalies v1.0.0"
        echo ""
    fi
    
    # Проверки
    if ! check_dependencies; then
        exit 1
    fi
    
    # Инициализация
    initialize_logs
    
    # Обнаружение аномалий
    detect_timeouts
    detect_repeat_calls
    detect_cycle_calls
    detect_unusual_patterns
    
    # Генерация отчетов
    generate_json_report > /dev/null
    generate_markdown_report > /dev/null
    
    # Вывод
    if [ "$QUIET" = false ]; then
        print_summary
        log_success "Анализ завершен"
        echo ""
        echo -e "${WHITE}Отчеты:${NC}"
        echo "  - JSON: $OUTPUT_DIR/anomaly-detection-$TIMESTAMP.json"
        echo "  - Markdown: $OUTPUT_DIR/anomaly-detection-$TIMESTAMP.md"
        echo ""
    fi
    
    # Выход с кодом ошибки если найдены критические аномалии
    local total_anomalies=$((${#TIMEOUT_ANOMALIES[@]} + ${#REPEAT_ANOMALIES[@]} + ${#CYCLE_ANOMALIES[@]} + ${#UNUSUAL_ANOMALIES[@]}))
    if [ "$total_anomalies" -gt 10 ]; then
        exit 2  # Критическое количество аномалий
    elif [ "$total_anomalies" -gt 0 ]; then
        exit 1  # Есть аномалии
    fi
    
    exit 0
}

main "$@"
