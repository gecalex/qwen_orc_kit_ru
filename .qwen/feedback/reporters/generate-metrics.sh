#!/bin/bash
#
# Generate Metrics
# Назначение: Генерация метрик для дашборда
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
REPORTS_DIR="${REPORTS_DIR:-$SCRIPT_DIR/../reports}"
OUTPUT_DIR="${OUTPUT_DIR:-$SCRIPT_DIR/../reports}"
TIMESTAMP=$(date +%Y-%m-%d_%H-%M-%S)

# Формат вывода (json или csv)
OUTPUT_FORMAT="${OUTPUT_FORMAT:-both}"

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

# Извлечение значения из JSON
get_json_value() {
    local json="$1"
    local key="$2"
    echo "$json" | grep -o "\"$key\":\s*[^,}]*" | head -1 | sed 's/.*:\s*//' | tr -d '"' | tr -d ' ' || echo "0"
}

# Сбор метрик из всех отчетов
collect_all_metrics() {
    log_info "Сбор метрик из отчетов..."
    
    # Инициализация переменных
    local git_score=0 git_grade="N/A" git_violations=0 git_warnings=0
    local spec_score=0 spec_grade="N/A" spec_compliance=0 spec_issues=0
    local agent_score=0 agent_grade="N/A" agent_anomalies=0 agent_errors=0
    local logic_score=0 logic_grade="N/A" logic_contradictions=0 logic_path_issues=0
    local quality_score=0 quality_grade="N/A" quality_trends=0 quality_predictions=0
    
    # Поиск и обработка отчетов
    local git_report
    git_report=$(find "$REPORTS_DIR" -name "git-workflow-analysis-*.json" -type f 2>/dev/null | sort -r | head -1)
    
    if [ -n "$git_report" ] && [ -f "$git_report" ]; then
        local git_data
        git_data=$(cat "$git_report")
        git_score=$(get_json_value "$git_data" "score")
        git_grade=$(get_json_value "$git_data" "grade")
        git_violations=$(echo "$git_data" | grep -o '"violations":\s*\[' | wc -l)
        git_warnings=$(echo "$git_data" | grep -o '"warnings":\s*\[' | wc -l)
    fi
    
    local spec_report
    spec_report=$(find "$REPORTS_DIR" -name "spec-compliance-analysis-*.json" -type f 2>/dev/null | sort -r | head -1)
    
    if [ -n "$spec_report" ] && [ -f "$spec_report" ]; then
        local spec_data
        spec_data=$(cat "$spec_report")
        spec_score=$(get_json_value "$spec_data" "score")
        spec_grade=$(get_json_value "$spec_data" "grade")
        spec_compliance=$(get_json_value "$spec_data" "compliance_percent")
        spec_issues=$(echo "$spec_data" | grep -o '"compliance_issues":\s*\[' | wc -l)
    fi
    
    local agent_report
    agent_report=$(find "$REPORTS_DIR" -name "agent-interaction-analysis-*.json" -type f 2>/dev/null | sort -r | head -1)
    
    if [ -n "$agent_report" ] && [ -f "$agent_report" ]; then
        local agent_data
        agent_data=$(cat "$agent_report")
        agent_score=$(get_json_value "$agent_data" "score")
        agent_grade=$(get_json_value "$agent_data" "grade")
        agent_anomalies=$(echo "$agent_data" | grep -o '"anomalies":\s*\[' | wc -l)
        agent_errors=$(get_json_value "$agent_data" "agent_errors")
    fi
    
    local logic_report
    logic_report=$(find "$REPORTS_DIR" -name "logic-consistency-analysis-*.json" -type f 2>/dev/null | sort -r | head -1)
    
    if [ -n "$logic_report" ] && [ -f "$logic_report" ]; then
        local logic_data
        logic_data=$(cat "$logic_report")
        logic_score=$(get_json_value "$logic_data" "score")
        logic_grade=$(get_json_value "$logic_data" "grade")
        logic_contradictions=$(echo "$logic_data" | grep -o '"contradictions":\s*\[' | wc -l)
        logic_path_issues=$(get_json_value "$logic_data" "path_issues")
    fi
    
    local quality_report
    quality_report=$(find "$REPORTS_DIR" -name "quality-trends-analysis-*.json" -type f 2>/dev/null | sort -r | head -1)
    
    if [ -n "$quality_report" ] && [ -f "$quality_report" ]; then
        local quality_data
        quality_data=$(cat "$quality_report")
        quality_score=$(get_json_value "$quality_data" "score")
        quality_grade=$(get_json_value "$quality_data" "grade")
        quality_trends=$(echo "$quality_data" | grep -o '"trends":\s*\[' | wc -l)
        quality_predictions=$(echo "$quality_data" | grep -o '"predictions":\s*\[' | wc -l)
    fi
    
    # Расчет общего score
    local total_score=0
    local count=0
    
    for score in "$git_score" "$spec_score" "$agent_score" "$logic_score" "$quality_score"; do
        if [ -n "$score" ] && [ "$score" != "0" ] && [ "$score" -gt 0 ] 2>/dev/null; then
            total_score=$((total_score + score))
            ((count++))
        fi
    done
    
    local avg_score=0
    if [ "$count" -gt 0 ]; then
        avg_score=$((total_score / count))
    fi
    
    # Вывод метрик
    echo "GIT_SCORE=$git_score"
    echo "GIT_GRADE=$git_grade"
    echo "GIT_VIOLATIONS=$git_violations"
    echo "GIT_WARNINGS=$git_warnings"
    echo ""
    echo "SPEC_SCORE=$spec_score"
    echo "SPEC_GRADE=$spec_grade"
    echo "SPEC_COMPLIANCE=$spec_compliance"
    echo "SPEC_ISSUES=$spec_issues"
    echo ""
    echo "AGENT_SCORE=$agent_score"
    echo "AGENT_GRADE=$agent_grade"
    echo "AGENT_ANOMALIES=$agent_anomalies"
    echo "AGENT_ERRORS=$agent_errors"
    echo ""
    echo "LOGIC_SCORE=$logic_score"
    echo "LOGIC_GRADE=$logic_grade"
    echo "LOGIC_CONTRADICTIONS=$logic_contradictions"
    echo "LOGIC_PATH_ISSUES=$logic_path_issues"
    echo ""
    echo "QUALITY_SCORE=$quality_score"
    echo "QUALITY_GRADE=$quality_grade"
    echo "QUALITY_TRENDS=$quality_trends"
    echo "QUALITY_PREDICTIONS=$quality_predictions"
    echo ""
    echo "AVG_SCORE=$avg_score"
    echo "TOTAL_REPORTS=$count"
    echo "TIMESTAMP=$TIMESTAMP"
}

# Генерация JSON метрик
generate_json_metrics() {
    log_info "Генерация JSON метрик..."
    
    local metrics_output
    metrics_output=$(collect_all_metrics)
    
    # Парсинг переменных
    local git_score spec_score agent_score logic_score quality_score avg_score
    git_score=$(echo "$metrics_output" | grep "^GIT_SCORE=" | cut -d= -f2)
    spec_score=$(echo "$metrics_output" | grep "^SPEC_SCORE=" | cut -d= -f2)
    agent_score=$(echo "$metrics_output" | grep "^AGENT_SCORE=" | cut -d= -f2)
    logic_score=$(echo "$metrics_output" | grep "^LOGIC_SCORE=" | cut -d= -f2)
    quality_score=$(echo "$metrics_output" | grep "^QUALITY_SCORE=" | cut -d= -f2)
    avg_score=$(echo "$metrics_output" | grep "^AVG_SCORE=" | cut -d= -f2)
    
    local git_grade spec_grade agent_grade logic_grade quality_grade
    git_grade=$(echo "$metrics_output" | grep "^GIT_GRADE=" | cut -d= -f2)
    spec_grade=$(echo "$metrics_output" | grep "^SPEC_GRADE=" | cut -d= -f2)
    agent_grade=$(echo "$metrics_output" | grep "^AGENT_GRADE=" | cut -d= -f2)
    logic_grade=$(echo "$metrics_output" | grep "^LOGIC_GRADE=" | cut -d= -f2)
    quality_grade=$(echo "$metrics_output" | grep "^QUALITY_GRADE=" | cut -d= -f2)
    
    local git_violations git_warnings spec_compliance spec_issues
    git_violations=$(echo "$metrics_output" | grep "^GIT_VIOLATIONS=" | cut -d= -f2)
    git_warnings=$(echo "$metrics_output" | grep "^GIT_WARNINGS=" | cut -d= -f2)
    spec_compliance=$(echo "$metrics_output" | grep "^SPEC_COMPLIANCE=" | cut -d= -f2)
    spec_issues=$(echo "$metrics_output" | grep "^SPEC_ISSUES=" | cut -d= -f2)
    
    local agent_anomalies agent_errors logic_contradictions logic_path_issues
    agent_anomalies=$(echo "$metrics_output" | grep "^AGENT_ANOMALIES=" | cut -d= -f2)
    agent_errors=$(echo "$metrics_output" | grep "^AGENT_ERRORS=" | cut -d= -f2)
    logic_contradictions=$(echo "$metrics_output" | grep "^LOGIC_CONTRADICTIONS=" | cut -d= -f2)
    logic_path_issues=$(echo "$metrics_output" | grep "^LOGIC_PATH_ISSUES=" | cut -d= -f2)
    
    local quality_trends quality_predictions total_reports
    quality_trends=$(echo "$metrics_output" | grep "^QUALITY_TRENDS=" | cut -d= -f2)
    quality_predictions=$(echo "$metrics_output" | grep "^QUALITY_PREDICTIONS=" | cut -d= -f2)
    total_reports=$(echo "$metrics_output" | grep "^TOTAL_REPORTS=" | cut -d= -f2)
    
    cat > "$OUTPUT_DIR/metrics-$TIMESTAMP.json" << EOF
{
  "timestamp": "$TIMESTAMP",
  "generated_at": "$(date -Iseconds)",
  "overall": {
    "average_score": ${avg_score:-0},
    "total_reports": ${total_reports:-0},
    "status": "$([ "${avg_score:-0}" -ge 70 ] && echo "healthy" || echo "needs_attention")"
  },
  "categories": {
    "git_workflow": {
      "score": ${git_score:-0},
      "grade": "${git_grade:-N/A}",
      "violations": ${git_violations:-0},
      "warnings": ${git_warnings:-0}
    },
    "spec_compliance": {
      "score": ${spec_score:-0},
      "grade": "${spec_grade:-N/A}",
      "compliance_percent": ${spec_compliance:-0},
      "issues": ${spec_issues:-0}
    },
    "agent_interaction": {
      "score": ${agent_score:-0},
      "grade": "${agent_grade:-N/A}",
      "anomalies": ${agent_anomalies:-0},
      "errors": ${agent_errors:-0}
    },
    "logic_consistency": {
      "score": ${logic_score:-0},
      "grade": "${logic_grade:-N/A}",
      "contradictions": ${logic_contradictions:-0},
      "path_issues": ${logic_path_issues:-0}
    },
    "quality_trends": {
      "score": ${quality_score:-0},
      "grade": "${quality_grade:-N/A}",
      "trends_count": ${quality_trends:-0},
      "predictions_count": ${quality_predictions:-0}
    }
  },
  "dashboard": {
    "gauge_value": ${avg_score:-0},
    "gauge_max": 100,
    "status_color": "$([ "${avg_score:-0}" -ge 80 ] && echo "green" || ([ "${avg_score:-0}" -ge 60 ] && echo "yellow" || echo "red"))",
    "sparkline_data": [${git_score:-0}, ${spec_score:-0}, ${agent_score:-0}, ${logic_score:-0}, ${quality_score:-0}]
  }
}
EOF
    
    log_success "JSON метрики сохранены: $OUTPUT_DIR/metrics-$TIMESTAMP.json"
}

# Генерация CSV метрик
generate_csv_metrics() {
    log_info "Генерация CSV метрик..."
    
    local metrics_output
    metrics_output=$(collect_all_metrics)
    
    local csv_file="$OUTPUT_DIR/metrics-$TIMESTAMP.csv"
    
    # Заголовок
    echo "timestamp,category,score,grade,metric1_name,metric1_value,metric2_name,metric2_value" > "$csv_file"
    
    # Git Workflow
    local git_score git_grade git_violations git_warnings
    git_score=$(echo "$metrics_output" | grep "^GIT_SCORE=" | cut -d= -f2)
    git_grade=$(echo "$metrics_output" | grep "^GIT_GRADE=" | cut -d= -f2)
    git_violations=$(echo "$metrics_output" | grep "^GIT_VIOLATIONS=" | cut -d= -f2)
    git_warnings=$(echo "$metrics_output" | grep "^GIT_WARNINGS=" | cut -d= -f2)
    echo "$TIMESTAMP,git_workflow,${git_score:-0},${git_grade:-N/A},violations,${git_violations:-0},warnings,${git_warnings:-0}" >> "$csv_file"
    
    # Spec Compliance
    local spec_score spec_grade spec_compliance spec_issues
    spec_score=$(echo "$metrics_output" | grep "^SPEC_SCORE=" | cut -d= -f2)
    spec_grade=$(echo "$metrics_output" | grep "^SPEC_GRADE=" | cut -d= -f2)
    spec_compliance=$(echo "$metrics_output" | grep "^SPEC_COMPLIANCE=" | cut -d= -f2)
    spec_issues=$(echo "$metrics_output" | grep "^SPEC_ISSUES=" | cut -d= -f2)
    echo "$TIMESTAMP,spec_compliance,${spec_score:-0},${spec_grade:-N/A},compliance_percent,${spec_compliance:-0},issues,${spec_issues:-0}" >> "$csv_file"
    
    # Agent Interaction
    local agent_score agent_grade agent_anomalies agent_errors
    agent_score=$(echo "$metrics_output" | grep "^AGENT_SCORE=" | cut -d= -f2)
    agent_grade=$(echo "$metrics_output" | grep "^AGENT_GRADE=" | cut -d= -f2)
    agent_anomalies=$(echo "$metrics_output" | grep "^AGENT_ANOMALIES=" | cut -d= -f2)
    agent_errors=$(echo "$metrics_output" | grep "^AGENT_ERRORS=" | cut -d= -f2)
    echo "$TIMESTAMP,agent_interaction,${agent_score:-0},${agent_grade:-N/A},anomalies,${agent_anomalies:-0},errors,${agent_errors:-0}" >> "$csv_file"
    
    # Logic Consistency
    local logic_score logic_grade logic_contradictions logic_path_issues
    logic_score=$(echo "$metrics_output" | grep "^LOGIC_SCORE=" | cut -d= -f2)
    logic_grade=$(echo "$metrics_output" | grep "^LOGIC_GRADE=" | cut -d= -f2)
    logic_contradictions=$(echo "$metrics_output" | grep "^LOGIC_CONTRADICTIONS=" | cut -d= -f2)
    logic_path_issues=$(echo "$metrics_output" | grep "^LOGIC_PATH_ISSUES=" | cut -d= -f2)
    echo "$TIMESTAMP,logic_consistency,${logic_score:-0},${logic_grade:-N/A},contradictions,${logic_contradictions:-0},path_issues,${logic_path_issues:-0}" >> "$csv_file"
    
    # Quality Trends
    local quality_score quality_grade quality_trends quality_predictions
    quality_score=$(echo "$metrics_output" | grep "^QUALITY_SCORE=" | cut -d= -f2)
    quality_grade=$(echo "$metrics_output" | grep "^QUALITY_GRADE=" | cut -d= -f2)
    quality_trends=$(echo "$metrics_output" | grep "^QUALITY_TRENDS=" | cut -d= -f2)
    quality_predictions=$(echo "$metrics_output" | grep "^QUALITY_PREDICTIONS=" | cut -d= -f2)
    echo "$TIMESTAMP,quality_trends,${quality_score:-0},${quality_grade:-N/A},trends,${quality_trends:-0},predictions,${quality_predictions:-0}" >> "$csv_file"
    
    # Overall
    local avg_score total_reports
    avg_score=$(echo "$metrics_output" | grep "^AVG_SCORE=" | cut -d= -f2)
    total_reports=$(echo "$metrics_output" | grep "^TOTAL_REPORTS=" | cut -d= -f2)
    echo "$TIMESTAMP,overall,${avg_score:-0},N/A,total_reports,${total_reports:-0},status,$([ "${avg_score:-0}" -ge 70 ] && echo "healthy" || echo "needs_attention")" >> "$csv_file"
    
    log_success "CSV метрики сохранены: $csv_file"
}

# Генерация dashboard-ready JSON (упрощенный формат для Grafana/Datadog)
generate_dashboard_json() {
    log_info "Генерация dashboard JSON..."
    
    local metrics_output
    metrics_output=$(collect_all_metrics)
    
    local avg_score
    avg_score=$(echo "$metrics_output" | grep "^AVG_SCORE=" | cut -d= -f2)
    
    local git_score spec_score agent_score logic_score quality_score
    git_score=$(echo "$metrics_output" | grep "^GIT_SCORE=" | cut -d= -f2)
    spec_score=$(echo "$metrics_output" | grep "^SPEC_SCORE=" | cut -d= -f2)
    agent_score=$(echo "$metrics_output" | grep "^AGENT_SCORE=" | cut -d= -f2)
    logic_score=$(echo "$metrics_output" | grep "^LOGIC_SCORE=" | cut -d= -f2)
    quality_score=$(echo "$metrics_output" | grep "^QUALITY_SCORE=" | cut -d= -f2)
    
    # Формат для Prometheus/Grafana
    cat > "$OUTPUT_DIR/dashboard-$TIMESTAMP.json" << EOF
{
  "metrics": [
    {"name": "feedback.overall.score", "value": ${avg_score:-0}, "timestamp": "$(date +%s)"},
    {"name": "feedback.git_workflow.score", "value": ${git_score:-0}, "timestamp": "$(date +%s)"},
    {"name": "feedback.spec_compliance.score", "value": ${spec_score:-0}, "timestamp": "$(date +%s)"},
    {"name": "feedback.agent_interaction.score", "value": ${agent_score:-0}, "timestamp": "$(date +%s)"},
    {"name": "feedback.logic_consistency.score", "value": ${logic_score:-0}, "timestamp": "$(date +%s)"},
    {"name": "feedback.quality_trends.score", "value": ${quality_score:-0}, "timestamp": "$(date +%s)"}
  ]
}
EOF
    
    log_success "Dashboard JSON сохранен: $OUTPUT_DIR/dashboard-$TIMESTAMP.json"
}

# Показать помощь
show_help() {
    cat << EOF
Generate Metrics v1.0.0

Назначение: Генерация метрик для дашборда

Использование:
  $(basename "$0") [OPTIONS]

Опции:
  -h, --help          Показать эту справку
  -v, --verbose       Подробный вывод
  -q, --quiet         Тихий режим
  -r, --reports-dir   Директория с отчетами (по умолчанию: ../reports)
  -o, --output        Директория для вывода (по умолчанию: ../reports)
  -f, --format        Формат вывода: json, csv, both (по умолчанию: both)

Примеры:
  $(basename "$0")                              # Запуск с настройками по умолчанию
  $(basename "$0") -f json                      # Только JSON
  $(basename "$0") -f csv                       # Только CSV
  $(basename "$0") -r /path/to/reports          # Указать директорию отчетов

Выход:
  JSON/CSV с метриками для визуализации
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
        -r|--reports-dir)
            REPORTS_DIR="$2"
            shift 2
            ;;
        -o|--output)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        -f|--format)
            OUTPUT_FORMAT="$2"
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
        echo "  Generate Metrics v1.0.0"
        echo "========================================"
        echo ""
    fi
    
    case "$OUTPUT_FORMAT" in
        json)
            generate_json_metrics
            generate_dashboard_json
            ;;
        csv)
            generate_csv_metrics
            ;;
        both|*)
            generate_json_metrics
            generate_csv_metrics
            generate_dashboard_json
            ;;
    esac
    
    if [ "$QUIET" = false ]; then
        echo ""
        echo "========================================"
        echo "  Метрики сгенерированы"
        echo "========================================"
        echo ""
        echo "Формат: $OUTPUT_FORMAT"
        echo "Директория: $OUTPUT_DIR"
    fi
}

main
