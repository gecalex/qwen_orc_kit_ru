#!/bin/bash
#
# Agent Call Analyzer - Анализ вызовов агентов и выявление паттернов
# Назначение: Чтение логов, подсчет вызовов, выявление аномалий, расчет метрик
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
LOGS_DIR="$PROJECT_ROOT/.qwen/logs"
ANALYTICS_DIR="$SCRIPT_DIR"
REPORTS_DIR="$SCRIPT_DIR/reports"
TIMESTAMP=$(date +%Y-%m-%d_%H-%M-%S)
DATE=$(date +%Y-%m-%d)

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
${WHITE}Agent Call Analyzer v1.0.0${NC}

Анализ вызовов агентов и выявление паттернов

${WHITE}Использование:${NC}
  $(basename "$0") [OPTIONS]

${WHITE}Опции:${NC}
  -h, --help              Показать эту справку
  -v, --verbose           Подробный вывод
  -q, --quiet             Тихий режим (только JSON)
  -o, --output DIR        Директория для вывода (по умолчанию: ./reports)
  -l, --log FILE          Файл логов (по умолчанию: .qwen/logs/agent-calls.log)

${WHITE}Примеры:${NC}
  $(basename "$0")                                    # Полный анализ
  $(basename "$0") -v                                 # Подробный вывод
  $(basename "$0") -o /tmp/analytics                  # Вывод в /tmp
  $(basename "$0") -l /path/to/custom.log             # Кастомный лог файл

${WHITE}Выход:${NC}
  - JSON отчет с метриками
  - Markdown отчет с визуализацией
  - STDOUT с краткой сводкой
EOF
}

# Проверка зависимостей
check_dependencies() {
    local missing=()

    if ! command -v jq &> /dev/null; then
        missing+=("jq")
    fi

    if ! command -v git &> /dev/null; then
        missing+=("git")
    fi

    if [ ${#missing[@]} -gt 0 ]; then
        log_error "Отсутствуют зависимости: ${missing[*]}"
        return 1
    fi

    return 0
}

# Инициализация логов (создание тестовых данных если файл пуст)
initialize_logs() {
    if [ ! -f "$LOG_FILE" ] || [ ! -s "$LOG_FILE" ]; then
        log_warning "Файл логов не найден или пуст. Создание тестовых данных..."
        mkdir -p "$LOGS_DIR"
        
        # Генерация тестовых логов
        cat > "$LOG_FILE" << 'LOGEOF'
2026-03-21T09:00:00Z|orc_planning_task_analyzer|started|task_001|Phase 0 Planning
2026-03-21T09:02:30Z|orc_planning_task_analyzer|completed|task_001|success|150s|tokens:4500
2026-03-21T09:03:00Z|orc_dev_task_coordinator|started|task_002|Dev Coordination
2026-03-21T09:07:45Z|orc_dev_task_coordinator|completed|task_002|success|285s|tokens:8200
2026-03-21T09:08:00Z|work_dev_code_analyzer|started|task_003|Code Analysis
2026-03-21T09:11:20Z|work_dev_code_analyzer|completed|task_003|success|200s|tokens:5600
2026-03-21T09:12:00Z|orc_testing_quality_assurer|started|task_004|Quality Assurance
2026-03-21T09:19:30Z|orc_testing_quality_assurer|completed|task_004|success|450s|tokens:12000
2026-03-21T09:20:00Z|bug-hunter|started|task_005|Bug Hunting
2026-03-21T09:23:15Z|bug-hunter|completed|task_005|success|195s|tokens:4800
2026-03-21T09:24:00Z|work_testing_test_generator|started|task_006|Test Generation
2026-03-21T09:26:45Z|work_testing_test_generator|failed|task_006|timeout|165s|tokens:3200
2026-03-21T09:27:00Z|work_testing_test_generator|started|task_006|Test Generation (retry 1)
2026-03-21T09:29:30Z|work_testing_test_generator|failed|task_006|timeout|150s|tokens:2900
2026-03-21T09:30:00Z|work_testing_test_generator|started|task_006|Test Generation (retry 2)
2026-03-21T09:32:45Z|work_testing_test_generator|failed|task_006|timeout|165s|tokens:3100
2026-03-21T09:33:00Z|work_testing_test_generator|started|task_006|Test Generation (retry 3)
2026-03-21T09:35:30Z|work_testing_test_generator|failed|task_006|timeout|150s|tokens:2800
2026-03-21T09:36:00Z|work_testing_test_generator|started|task_006|Test Generation (retry 4)
2026-03-21T09:38:45Z|work_testing_test_generator|completed|task_006|success|165s|tokens:3500
2026-03-21T09:40:00Z|orc_planning_task_analyzer|started|task_007|Phase 0 Planning
2026-03-21T09:42:15Z|orc_planning_task_analyzer|completed|task_007|success|135s|tokens:4200
2026-03-21T09:43:00Z|orc_dev_task_coordinator|started|task_008|Dev Coordination
2026-03-21T09:50:30Z|orc_dev_task_coordinator|completed|task_008|success|450s|tokens:9800
2026-03-21T09:51:00Z|security-analyzer|started|task_009|Security Analysis
2026-03-21T09:54:45Z|security-analyzer|completed|task_009|success|225s|tokens:6100
2026-03-21T09:55:00Z|orc_testing_quality_assurer|started|task_010|Quality Assurance
2026-03-21T10:03:30Z|orc_testing_quality_assurer|completed|task_010|success|510s|tokens:13500
2026-03-21T10:04:00Z|orc_dev_task_coordinator|started|task_011|Dev Coordination
2026-03-21T10:09:15Z|orc_dev_task_coordinator|completed|task_011|success|315s|tokens:7900
2026-03-21T10:10:00Z|work_dev_code_analyzer|started|task_012|Code Analysis
2026-03-21T10:13:40Z|work_dev_code_analyzer|completed|task_012|success|220s|tokens:5900
2026-03-21T10:14:00Z|orc_planning_task_analyzer|started|task_013|Phase 0 Planning
2026-03-21T10:16:25Z|orc_planning_task_analyzer|completed|task_013|success|145s|tokens:4400
2026-03-21T10:17:00Z|bug-hunter|started|task_014|Bug Hunting
2026-03-21T10:20:30Z|bug-hunter|completed|task_014|success|210s|tokens:5100
2026-03-21T10:21:00Z|orc_dev_task_coordinator|started|task_015|Dev Coordination
2026-03-21T10:26:45Z|orc_dev_task_coordinator|completed|task_015|success|345s|tokens:8500
2026-03-21T10:27:00Z|work_testing_test_generator|started|task_016|Test Generation
2026-03-21T10:29:45Z|work_testing_test_generator|completed|task_016|success|165s|tokens:3800
2026-03-21T10:30:00Z|orc_testing_quality_assurer|started|task_017|Quality Assurance
2026-03-21T10:38:15Z|orc_testing_quality_assurer|completed|task_017|success|495s|tokens:12800
2026-03-21T10:39:00Z|orc_planning_task_analyzer|started|task_018|Phase 0 Planning
2026-03-21T10:41:20Z|orc_planning_task_analyzer|completed|task_018|success|140s|tokens:4300
2026-03-21T10:42:00Z|orc_dev_task_coordinator|started|task_019|Dev Coordination
2026-03-21T10:47:30Z|orc_dev_task_coordinator|completed|task_019|success|330s|tokens:8100
2026-03-21T10:48:00Z|bug-hunter|started|task_020|Bug Hunting
2026-03-21T10:51:45Z|bug-hunter|completed|task_020|success|225s|tokens:5400
2026-03-21T10:52:00Z|work_dev_code_analyzer|started|task_021|Code Analysis
2026-03-21T10:55:30Z|work_dev_code_analyzer|completed|task_021|success|210s|tokens:5700
2026-03-21T10:56:00Z|orc_testing_quality_assurer|started|task_022|Quality Assurance
2026-03-21T11:04:45Z|orc_testing_quality_assurer|completed|task_022|success|525s|tokens:13200
2026-03-21T11:05:00Z|orc_planning_task_analyzer|started|task_023|Phase 0 Planning
2026-03-21T11:07:25Z|orc_planning_task_analyzer|completed|task_023|success|145s|tokens:4500
2026-03-21T11:08:00Z|orc_dev_task_coordinator|started|task_024|Dev Coordination
2026-03-21T11:13:45Z|orc_dev_task_coordinator|completed|task_024|success|345s|tokens:8400
2026-03-21T11:14:00Z|security-analyzer|started|task_025|Security Analysis
2026-03-21T11:17:50Z|security-analyzer|completed|task_025|success|230s|tokens:6300
2026-03-21T11:18:00Z|work_testing_test_generator|started|task_026|Test Generation
2026-03-21T11:20:45Z|work_testing_test_generator|completed|task_026|success|165s|tokens:3900
2026-03-21T11:21:00Z|orc_testing_quality_assurer|started|task_027|Quality Assurance
2026-03-21T11:29:30Z|orc_testing_quality_assurer|completed|task_027|success|510s|tokens:13000
2026-03-21T11:30:00Z|orc_planning_task_analyzer|started|task_028|Phase 0 Planning
2026-03-21T11:32:20Z|orc_planning_task_analyzer|completed|task_028|success|140s|tokens:4400
2026-03-21T11:33:00Z|orc_dev_task_coordinator|started|task_029|Dev Coordination
2026-03-21T11:38:30Z|orc_dev_task_coordinator|completed|task_029|success|330s|tokens:8200
2026-03-21T11:39:00Z|bug-hunter|started|task_030|Bug Hunting
2026-03-21T11:42:45Z|bug-hunter|completed|task_030|success|225s|tokens:5500
2026-03-21T14:00:00Z|orc_dev_task_coordinator|started|task_031|Dev Coordination (peak)
2026-03-21T14:05:30Z|orc_dev_task_coordinator|completed|task_031|success|330s|tokens:8300
2026-03-21T14:06:00Z|orc_dev_task_coordinator|started|task_032|Dev Coordination (peak)
2026-03-21T14:11:45Z|orc_dev_task_coordinator|completed|task_032|success|345s|tokens:8600
2026-03-21T14:12:00Z|orc_dev_task_coordinator|started|task_033|Dev Coordination (peak)
2026-03-21T14:17:30Z|orc_dev_task_coordinator|completed|task_033|success|330s|tokens:8100
2026-03-21T14:18:00Z|orc_dev_task_coordinator|started|task_034|Dev Coordination (peak)
2026-03-21T14:23:45Z|orc_dev_task_coordinator|completed|task_034|success|345s|tokens:8500
2026-03-21T14:24:00Z|orc_dev_task_coordinator|started|task_035|Dev Coordination (peak)
2026-03-21T14:29:30Z|orc_dev_task_coordinator|completed|task_035|success|330s|tokens:8200
2026-03-21T15:00:00Z|orc_planning_task_analyzer|started|task_036|Phase 0 Planning (peak)
2026-03-21T15:02:25Z|orc_planning_task_analyzer|completed|task_036|success|145s|tokens:4500
2026-03-21T15:03:00Z|orc_planning_task_analyzer|started|task_037|Phase 0 Planning (peak)
2026-03-21T15:05:20Z|orc_planning_task_analyzer|completed|task_037|success|140s|tokens:4300
2026-03-21T15:06:00Z|orc_planning_task_analyzer|started|task_038|Phase 0 Planning (peak)
2026-03-21T15:08:25Z|orc_planning_task_analyzer|completed|task_038|success|145s|tokens:4600
2026-03-21T15:09:00Z|orc_planning_task_analyzer|started|task_039|Phase 0 Planning (peak)
2026-03-21T15:11:20Z|orc_planning_task_analyzer|completed|task_039|success|140s|tokens:4400
2026-03-21T15:12:00Z|orc_planning_task_analyzer|started|task_040|Phase 0 Planning (peak)
2026-03-21T15:14:25Z|orc_planning_task_analyzer|completed|task_040|success|145s|tokens:4500
LOGEOF
        
        log_success "Тестовые данные созданы: $LOG_FILE"
    fi
}

# Парсинг логов
parse_logs() {
    log_step "Парсинг логов..."
    
    local total_lines=$(wc -l < "$LOG_FILE")
    log_info "Всего записей в логе: $total_lines"
    
    # Извлечение уникальных агентов
    AGENTS=$(cut -d'|' -f2 "$LOG_FILE" | sort -u)
    log_info "Уникальных агентов: $(echo "$AGENTS" | wc -l)"
}

# Подсчет вызовов по агентам
count_agent_calls() {
    log_step "Подсчет вызовов по агентам..."
    
    declare -gA AGENT_CALLS
    declare -gA AGENT_SUCCESS
    declare -gA AGENT_FAILED
    declare -gA AGENT_TOTAL_TIME
    declare -gA AGENT_TOTAL_TOKENS
    
    while IFS= read -r agent; do
        local calls=$(grep "|${agent}|" "$LOG_FILE" | grep "|started|" | wc -l)
        local success=$(grep "|${agent}|" "$LOG_FILE" | grep "|completed|" | grep "|success|" | wc -l)
        local failed=$(grep "|${agent}|" "$LOG_FILE" | grep "|completed|" | grep -E "|(failed|timeout)|" | wc -l)
        
        # Подсчет времени и токенов
        local total_time=0
        local total_tokens=0
        
        while IFS='|' read -r timestamp name status task result rest; do
            if [[ "$name" == "$agent" && "$status" == "completed" ]]; then
                # Извлечение времени из rest (формат: XXXs|tokens:YYYY)
                if [[ "$rest" =~ ([0-9]+)s ]]; then
                    total_time=$((total_time + BASH_REMATCH[1]))
                fi
                if [[ "$rest" =~ tokens:([0-9]+) ]]; then
                    total_tokens=$((total_tokens + BASH_REMATCH[1]))
                fi
            fi
        done < "$LOG_FILE"
        
        AGENT_CALLS["$agent"]=$calls
        AGENT_SUCCESS["$agent"]=$success
        AGENT_FAILED["$agent"]=$failed
        AGENT_TOTAL_TIME["$agent"]=$total_time
        AGENT_TOTAL_TOKENS["$agent"]=$total_tokens
        
    done <<< "$AGENTS"
}

# Выявление аномалий
detect_anomalies() {
    log_step "Выявление аномалий..."

    declare -gA ANOMALIES
    declare -ga ANOMALY_LIST=()

    # Поиск повторных вызовов
    while IFS= read -r agent; do
        local failed=$(grep "|${agent}|" "$LOG_FILE" | grep -E "|(failed|timeout)|" | wc -l)
        if [ "$failed" -gt 3 ]; then
            ANOMALY_LIST+=("repeat_calls:$agent:$failed повторных вызовов")
        fi
    done <<< "$AGENTS"

    # Поиск агентов с долгим средним временем
    for agent in "${!AGENT_CALLS[@]}"; do
        local calls=${AGENT_CALLS[$agent]}
        local time=${AGENT_TOTAL_TIME[$agent]}
        if [ "$calls" -gt 0 ]; then
            local avg_time=$((time / calls))
            if [ "$avg_time" -gt 300 ]; then  # > 5 минут
                ANOMALY_LIST+=("slow_agent:$agent:среднее время ${avg_time}с (>5 мин)")
            fi
        fi
    done
}

# Расчет метрик
calculate_metrics() {
    log_step "Расчет метрик..."
    
    local total_calls=0
    local total_success=0
    local total_failed=0
    local total_time=0
    local total_tokens=0
    
    for agent in "${!AGENT_CALLS[@]}"; do
        total_calls=$((total_calls + AGENT_CALLS[$agent]))
        total_success=$((total_success + AGENT_SUCCESS[$agent]))
        total_failed=$((total_failed + AGENT_FAILED[$agent]))
        total_time=$((total_time + AGENT_TOTAL_TIME[$agent]))
        total_tokens=$((total_tokens + AGENT_TOTAL_TOKENS[$agent]))
    done
    
    # Глобальные метрики
    declare -g TOTAL_CALLS=$total_calls
    declare -g TOTAL_SUCCESS=$total_success
    declare -g TOTAL_FAILED=$total_failed
    declare -g TOTAL_TIME=$total_time
    declare -g TOTAL_TOKENS=$total_tokens
    
    if [ "$total_calls" -gt 0 ]; then
        declare -g AVG_TIME=$((total_time / total_calls))
        declare -g SUCCESS_RATE=$((total_success * 100 / total_calls))
    else
        declare -g AVG_TIME=0
        declare -g SUCCESS_RATE=0
    fi
    
    # Пиковая нагрузка (по часам)
    declare -g PEAK_HOUR=$(cut -d'|' -f1 "$LOG_FILE" | cut -d'T' -f2 | cut -d':' -f1 | sort | uniq -c | sort -rn | head -1 | awk '{print $2}')
}

# Генерация JSON отчета
generate_json_report() {
    log_step "Генерация JSON отчета..."
    
    local json_file="$OUTPUT_DIR/agent-call-analysis-$TIMESTAMP.json"
    
    # Построение JSON
    local agents_json="{"
    local first=true
    
    for agent in "${!AGENT_CALLS[@]}"; do
        if [ "$first" = false ]; then
            agents_json+=","
        fi
        first=false
        
        local calls=${AGENT_CALLS[$agent]}
        local success=${AGENT_SUCCESS[$agent]}
        local failed=${AGENT_FAILED[$agent]}
        local time=${AGENT_TOTAL_TIME[$agent]}
        local tokens=${AGENT_TOTAL_TOKENS[$agent]}
        local success_rate=0
        
        if [ "$calls" -gt 0 ]; then
            success_rate=$((success * 100 / calls))
        fi
        
        agents_json+="
    \"$agent\": {
      \"calls\": $calls,
      \"success\": $success,
      \"failed\": $failed,
      \"success_rate\": $success_rate,
      \"total_time_seconds\": $time,
      \"total_tokens\": $tokens
    }"
    done
    
    agents_json+="
  }"
    
    # Аномалии JSON
    local anomalies_json="["
    first=true
    for anomaly in "${ANOMALY_LIST[@]}"; do
        if [ "$first" = false ]; then
            anomalies_json+=","
        fi
        first=false
        
        IFS=':' read -r type agent desc <<< "$anomaly"
        anomalies_json+="
    {
      \"type\": \"$type\",
      \"agent\": \"$agent\",
      \"description\": \"$desc\"
    }"
    done
    anomalies_json+="
  ]"
    
    cat > "$json_file" << EOF
{
  "timestamp": "$TIMESTAMP",
  "date": "$DATE",
  "log_file": "$LOG_FILE",
  "summary": {
    "total_calls": $TOTAL_CALLS,
    "total_success": $TOTAL_SUCCESS,
    "total_failed": $TOTAL_FAILED,
    "success_rate": $SUCCESS_RATE,
    "average_time_seconds": $AVG_TIME,
    "total_time_seconds": $TOTAL_TIME,
    "total_tokens": $TOTAL_TOKENS,
    "peak_hour": "${PEAK_HOUR}:00"
  },
  "agents": $agents_json,
  "anomalies": $anomalies_json
}
EOF
    
    log_success "JSON отчет: $json_file"
    echo "$json_file"
}

# Генерация Markdown отчета
generate_markdown_report() {
    log_step "Генерация Markdown отчета..."
    
    local md_file="$OUTPUT_DIR/agent-call-analysis-$TIMESTAMP.md"
    
    cat > "$md_file" << EOF
# Agent Call Analysis Report

**Дата**: $DATE  
**Время генерации**: $TIMESTAMP  
**Файл логов**: $LOG_FILE

---

## Executive Summary

| Метрика | Значение |
|---------|----------|
| Всего вызовов | $TOTAL_CALLS |
| Успешных | $TOTAL_SUCCESS |
| Неудачных | $TOTAL_FAILED |
| Успешность | ${SUCCESS_RATE}% |
| Среднее время | ${AVG_TIME}с |
| Общее время | ${TOTAL_TIME}с ($(($TOTAL_TIME / 60)) мин) |
| Всего токенов | $TOTAL_TOKENS |
| Пиковая нагрузка | ${PEAK_HOUR}:00 |

---

## Agent Call Statistics

EOF

    # Таблица агентов
    echo "| Агент | Вызовы | Успех | Ошибки | Успешность | Время (с) | Токены |" >> "$md_file"
    echo "|-------|--------|-------|--------|------------|-----------|--------|" >> "$md_file"
    
    for agent in "${!AGENT_CALLS[@]}"; do
        local calls=${AGENT_CALLS[$agent]}
        local success=${AGENT_SUCCESS[$agent]}
        local failed=${AGENT_FAILED[$agent]}
        local time=${AGENT_TOTAL_TIME[$agent]}
        local tokens=${AGENT_TOTAL_TOKENS[$agent]}
        local success_rate=0
        
        if [ "$calls" -gt 0 ]; then
            success_rate=$((success * 100 / calls))
        fi
        
        echo "| $agent | $calls | $success | $failed | ${success_rate}% | $time | $tokens |" >> "$md_file"
    done
    
    cat >> "$md_file" << EOF

---

## Anomalies Detected

EOF

    if [ ${#ANOMALY_LIST[@]} -eq 0 ]; then
        echo "✅ Аномалий не обнаружено" >> "$md_file"
    else
        for anomaly in "${ANOMALY_LIST[@]}"; do
            IFS=':' read -r type agent desc <<< "$anomaly"
            case "$type" in
                repeat_calls)
                    echo "⚠️ **$agent**: $desc" >> "$md_file"
                    ;;
                slow_agent)
                    echo "⚠️ **$agent**: $desc" >> "$md_file"
                    ;;
                *)
                    echo "⚠️ **$agent**: $desc" >> "$md_file"
                    ;;
            esac
        done
    fi
    
    cat >> "$md_file" << EOF

---

## Performance Metrics

- **Среднее время выполнения**: ${AVG_TIME}с
- **Успешность**: ${SUCCESS_RATE}%
- **Пиковая нагрузка**: ${PEAK_HOUR}:00

---

## Recommendations

EOF

    # Генерация рекомендаций
    local has_recommendations=false
    
    for anomaly in "${ANOMALY_LIST[@]}"; do
        IFS=':' read -r type agent desc <<< "$anomaly"
        has_recommendations=true
        
        case "$type" in
            repeat_calls)
                echo "1. **$agent**: Проверить причины повторных вызовов, рассмотреть увеличение timeout или оптимизацию логики" >> "$md_file"
                ;;
            slow_agent)
                echo "1. **$agent**: Оптимизировать выполнение, рассмотреть разделение на подзадачи или кэширование" >> "$md_file"
                ;;
        esac
    done
    
    if [ "$has_recommendations" = false ]; then
        echo "✅ Рекомендаций нет - система работает оптимально" >> "$md_file"
    fi
    
    cat >> "$md_file" << EOF

---

## Trend Analysis

### Calls by Hour

EOF

    # Анализ по часам
    echo '```' >> "$md_file"
    cut -d'|' -f1 "$LOG_FILE" | cut -d'T' -f2 | cut -d':' -f1 | sort | uniq -c | sort -k2 | while read count hour; do
        printf "%s:00 | %s\n" "$hour" "$(printf '█%.0s' $(seq 1 $count))"
    done >> "$md_file"
    echo '```' >> "$md_file"
    
    log_success "Markdown отчет: $md_file"
    echo "$md_file"
}

# Вывод краткой сводки
print_summary() {
    echo ""
    log_header "Agent Call Statistics"
    echo ""
    
    # Статистика по агентам
    echo -e "${WHITE}Агенты:${NC}"
    for agent in "${!AGENT_CALLS[@]}"; do
        local calls=${AGENT_CALLS[$agent]}
        local success=${AGENT_SUCCESS[$agent]}
        local success_rate=0
        
        if [ "$calls" -gt 0 ]; then
            success_rate=$((success * 100 / calls))
        fi
        
        local status_color="$GREEN"
        if [ "$success_rate" -lt 90 ]; then
            status_color="$YELLOW"
        fi
        if [ "$success_rate" -lt 70 ]; then
            status_color="$RED"
        fi
        
        echo -e "  - $agent: $calls вызовов (${status_color}${success_rate}% успех${NC})"
    done
    
    echo ""
    
    # Аномалии
    if [ ${#ANOMALY_LIST[@]} -gt 0 ]; then
        echo -e "${WHITE}Anomalies Detected:${NC}"
        for anomaly in "${ANOMALY_LIST[@]}"; do
            IFS=':' read -r type agent desc <<< "$anomaly"
            echo -e "  ${YELLOW}⚠️${NC} $agent: $desc"
        done
        echo ""
    fi
    
    # Метрики
    echo -e "${WHITE}Performance Metrics:${NC}"
    echo "  - Среднее время выполнения: ${AVG_TIME}с"
    echo "  - Успешность: ${SUCCESS_RATE}%"
    echo "  - Пиковая нагрузка: ${PEAK_HOUR}:00"
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
        log_header "Agent Call Analyzer v1.0.0"
        echo ""
    fi
    
    # Проверки
    if ! check_dependencies; then
        exit 1
    fi
    
    # Инициализация
    initialize_logs
    
    # Анализ
    parse_logs
    count_agent_calls
    detect_anomalies
    calculate_metrics
    
    # Генерация отчетов
    generate_json_report > /dev/null
    generate_markdown_report > /dev/null
    
    # Вывод
    if [ "$QUIET" = false ]; then
        print_summary
    fi
    
    if [ "$QUIET" = false ]; then
        log_success "Анализ завершен"
        echo ""
        echo -e "${WHITE}Отчеты:${NC}"
        echo "  - JSON: $OUTPUT_DIR/agent-call-analysis-$TIMESTAMP.json"
        echo "  - Markdown: $OUTPUT_DIR/agent-call-analysis-$TIMESTAMP.md"
        echo ""
    fi
    
    exit 0
}

main "$@"
