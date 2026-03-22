#!/bin/bash
#
# Generate Feedback Report
# Назначение: Генерация итогового отчета из JSON анализаторов
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
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPORTS_DIR="${REPORTS_DIR:-$SCRIPT_DIR/../reports}"
OUTPUT_DIR="${OUTPUT_DIR:-$SCRIPT_DIR/../reports}"
TIMESTAMP=$(date +%Y-%m-%d)
REPORT_FILE="$OUTPUT_DIR/feedback-report-$TIMESTAMP.md"

# Переменные для хранения данных
GIT_WORKFLOW_DATA=""
SPEC_COMPLIANCE_DATA=""
AGENT_INTERACTION_DATA=""
LOGIC_CONSISTENCY_DATA=""
QUALITY_TRENDS_DATA=""

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

# Загрузка JSON данных
load_json_data() {
    log_info "Загрузка данных анализаторов..."
    
    # Поиск последних отчетов
    local git_report
    git_report=$(find "$REPORTS_DIR" -name "git-workflow-analysis-*.json" -type f 2>/dev/null | sort -r | head -1)
    
    local spec_report
    spec_report=$(find "$REPORTS_DIR" -name "spec-compliance-analysis-*.json" -type f 2>/dev/null | sort -r | head -1)
    
    local agent_report
    agent_report=$(find "$REPORTS_DIR" -name "agent-interaction-analysis-*.json" -type f 2>/dev/null | sort -r | head -1)
    
    local logic_report
    logic_report=$(find "$REPORTS_DIR" -name "logic-consistency-analysis-*.json" -type f 2>/dev/null | sort -r | head -1)
    
    local quality_report
    quality_report=$(find "$REPORTS_DIR" -name "quality-trends-analysis-*.json" -type f 2>/dev/null | sort -r | head -1)
    
    # Загрузка данных
    if [ -n "$git_report" ] && [ -f "$git_report" ]; then
        GIT_WORKFLOW_DATA=$(cat "$git_report")
        log_success "Загружен Git Workflow отчет"
    else
        log_warning "Git Workflow отчет не найден"
        GIT_WORKFLOW_DATA='{"status": "no_data", "score": 0, "warnings": [], "recommendations": []}'
    fi
    
    if [ -n "$spec_report" ] && [ -f "$spec_report" ]; then
        SPEC_COMPLIANCE_DATA=$(cat "$spec_report")
        log_success "Загружен Spec Compliance отчет"
    else
        log_warning "Spec Compliance отчет не найден"
        SPEC_COMPLIANCE_DATA='{"status": "no_data", "score": 0, "compliance_issues": [], "recommendations": []}'
    fi
    
    if [ -n "$agent_report" ] && [ -f "$agent_report" ]; then
        AGENT_INTERACTION_DATA=$(cat "$agent_report")
        log_success "Загружен Agent Interaction отчет"
    else
        log_warning "Agent Interaction отчет не найден"
        AGENT_INTERACTION_DATA='{"status": "no_data", "score": 0, "anomalies": [], "recommendations": []}'
    fi
    
    if [ -n "$logic_report" ] && [ -f "$logic_report" ]; then
        LOGIC_CONSISTENCY_DATA=$(cat "$logic_report")
        log_success "Загружен Logic Consistency отчет"
    else
        log_warning "Logic Consistency отчет не найден"
        LOGIC_CONSISTENCY_DATA='{"status": "no_data", "score": 0, "contradictions": [], "recommendations": []}'
    fi
    
    if [ -n "$quality_report" ] && [ -f "$quality_report" ]; then
        QUALITY_TRENDS_DATA=$(cat "$quality_report")
        log_success "Загружен Quality Trends отчет"
    else
        log_warning "Quality Trends отчет не найден"
        QUALITY_TRENDS_DATA='{"status": "no_data", "score": 0, "trends": [], "recommendations": []}'
    fi
}

# Извлечение значения из JSON
get_json_value() {
    local json="$1"
    local key="$2"
    echo "$json" | grep -o "\"$key\":\s*[^,}]*" | head -1 | sed 's/.*:\s*//' | tr -d '"' | tr -d ' '
}

# Извлечение массива из JSON
get_json_array() {
    local json="$1"
    local key="$2"
    # Простое извлечение элементов массива
    echo "$json" | grep -o "\"$key\":\s*\[[^]]*\]" | sed 's/.*\[\(.*\)\]/\1/' | tr ',' '\n' | tr -d '"' | tr -d ' ' | grep -v '^$' || echo ""
}

# Генерация Executive Summary
generate_executive_summary() {
    local git_score
    git_score=$(get_json_value "$GIT_WORKFLOW_DATA" "score")
    local spec_score
    spec_score=$(get_json_value "$SPEC_COMPLIANCE_DATA" "score")
    local agent_score
    agent_score=$(get_json_value "$AGENT_INTERACTION_DATA" "score")
    local logic_score
    logic_score=$(get_json_value "$LOGIC_CONSISTENCY_DATA" "score")
    local quality_score
    quality_score=$(get_json_value "$QUALITY_TRENDS_DATA" "score")
    
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
    
    # Определение общей оценки
    local overall_grade="F"
    if [ "$avg_score" -ge 90 ]; then
        overall_grade="A (Отлично)"
    elif [ "$avg_score" -ge 80 ]; then
        overall_grade="B (Хорошо)"
    elif [ "$avg_score" -ge 70 ]; then
        overall_grade="C (Удовлетворительно)"
    elif [ "$avg_score" -ge 60 ]; then
        overall_grade="D (Требует улучшения)"
    fi
    
    # Подсчет критических проблем
    local critical_issues=0
    
    local git_violations
    git_violations=$(echo "$GIT_WORKFLOW_DATA" | grep -o '"violations":\s*\[' | wc -l)
    local spec_issues
    spec_issues=$(echo "$SPEC_COMPLIANCE_DATA" | grep -o '"compliance_issues":\s*\[' | wc -l)
    local agent_anomalies
    agent_anomalies=$(echo "$AGENT_INTERACTION_DATA" | grep -o '"anomalies":\s*\[' | wc -l)
    local logic_contradictions
    logic_contradictions=$(echo "$LOGIC_CONSISTENCY_DATA" | grep -o '"contradictions":\s*\[' | wc -l)
    
    critical_issues=$((git_violations + spec_issues + agent_anomalies + logic_contradictions))
    
    cat << EOF
## Executive Summary

### Общая оценка

| Метрика | Значение |
|---------|----------|
| **Средний Score** | $avg_score/100 |
| **Оценка** | $overall_grade |
| **Дата отчета** | $TIMESTAMP |
| **Анализаторов запущено** | $count/5 |

### Scores по областям

| Область | Score | Статус |
|---------|-------|--------|
| Git Workflow | ${git_score:-N/A}/100 | $(if [ "${git_score:-0}" -ge 70 ] 2>/dev/null; then echo "✅"; else echo "⚠️"; fi) |
| Spec Compliance | ${spec_score:-N/A}/100 | $(if [ "${spec_score:-0}" -ge 70 ] 2>/dev/null; then echo "✅"; else echo "⚠️"; fi) |
| Agent Interaction | ${agent_score:-N/A}/100 | $(if [ "${agent_score:-0}" -ge 70 ] 2>/dev/null; then echo "✅"; else echo "⚠️"; fi) |
| Logic Consistency | ${logic_score:-N/A}/100 | $(if [ "${logic_score:-0}" -ge 70 ] 2>/dev/null; then echo "✅"; else echo "⚠️"; fi) |
| Quality Trends | ${quality_score:-N/A}/100 | $(if [ "${quality_score:-0}" -ge 70 ] 2>/dev/null; then echo "✅"; else echo "⚠️"; fi) |

### Критические проблемы

${critical_issues} проблем требуют внимания.

EOF

    # Рекомендации высокого уровня
    echo "### Ключевые рекомендации"
    echo ""
    
    if [ "$avg_score" -lt 70 ]; then
        echo "1. **Приоритет**: Проведите анализ проблемных областей"
    fi
    
    if [ "${git_score:-0}" -lt 70 ] 2>/dev/null; then
        echo "2. **Git Workflow**: Требуется улучшение процессов работы с git"
    fi
    
    if [ "${spec_score:-0}" -lt 70 ] 2>/dev/null; then
        echo "3. **Spec Compliance**: Необходимо улучшить соответствие спецификациям"
    fi
    
    if [ "${agent_score:-0}" -lt 70 ] 2>/dev/null; then
        echo "4. **Agent Interaction**: Проверьте взаимодействие агентов"
    fi
    
    echo ""
}

# Генерация секции Git Workflow
generate_git_workflow_section() {
    cat << EOF
## Git Workflow Analysis

EOF

    local score
    score=$(get_json_value "$GIT_WORKFLOW_DATA" "score")
    local grade
    grade=$(get_json_value "$GIT_WORKFLOW_DATA" "grade")
    
    echo "**Score**: ${score:-N/A}/100 (${grade:-N/A})"
    echo ""
    
    # Нарушения
    echo "### Нарушения"
    echo ""
    
    local violations
    violations=$(echo "$GIT_WORKFLOW_DATA" | grep -o '"violations":\s*\[[^]]*\]' | sed 's/"violations":\s*\[//' | sed 's/\]$//' | tr ',' '\n' | tr -d '"' | grep -v '^\s*$' || echo "")
    
    if [ -n "$violations" ]; then
        echo "$violations" | while read -r line; do
            if [ -n "$line" ]; then
                echo "- ❌ $line"
            fi
        done
    else
        echo "- ✅ Нарушений не обнаружено"
    fi
    
    echo ""
    
    # Предупреждения
    echo "### Предупреждения"
    echo ""
    
    local warnings
    warnings=$(echo "$GIT_WORKFLOW_DATA" | grep -o '"warnings":\s*\[[^]]*\]' | sed 's/"warnings":\s*\[//' | sed 's/\]$//' | tr ',' '\n' | tr -d '"' | grep -v '^\s*$' || echo "")
    
    if [ -n "$warnings" ]; then
        echo "$warnings" | while read -r line; do
            if [ -n "$line" ]; then
                echo "- ⚠️ $line"
            fi
        done
    else
        echo "- ✅ Предупреждений нет"
    fi
    
    echo ""
    
    # Рекомендации
    echo "### Рекомендации"
    echo ""
    
    local recs
    recs=$(echo "$GIT_WORKFLOW_DATA" | grep -o '"recommendations":\s*\[[^]]*\]' | sed 's/"recommendations":\s*\[//' | sed 's/\]$//' | tr ',' '\n' | tr -d '"' | grep -v '^\s*$' || echo "")
    
    if [ -n "$recs" ]; then
        echo "$recs" | while read -r line; do
            if [ -n "$line" ]; then
                echo "- 💡 $line"
            fi
        done
    else
        echo "- ✅ Рекомендаций нет"
    fi
    
    echo ""
}

# Генерация секции Spec Compliance
generate_spec_compliance_section() {
    cat << EOF
## Specification Compliance

EOF

    local score
    score=$(get_json_value "$SPEC_COMPLIANCE_DATA" "score")
    local grade
    grade=$(get_json_value "$SPEC_COMPLIANCE_DATA" "grade")
    
    echo "**Score**: ${score:-N/A}/100 (${grade:-N/A})"
    echo ""
    
    # Метрики
    echo "### Метрики"
    echo ""
    
    local total_specs
    total_specs=$(get_json_value "$SPEC_COMPLIANCE_DATA" "total_specs")
    local compliant_specs
    compliant_specs=$(get_json_value "$SPEC_COMPLIANCE_DATA" "compliant_specs")
    local compliance_percent
    compliance_percent=$(get_json_value "$SPEC_COMPLIANCE_DATA" "compliance_percent")
    
    echo "| Метрика | Значение |"
    echo "|---------|----------|"
    echo "| Всего спецификаций | ${total_specs:-0} |"
    echo "| Соответствуют | ${compliant_specs:-0} |"
    echo "| Процент соответствия | ${compliance_percent:-0}% |"
    echo ""
    
    # Проблемы соответствия
    echo "### Пробелы соответствия"
    echo ""
    
    local issues
    issues=$(echo "$SPEC_COMPLIANCE_DATA" | grep -o '"compliance_issues":\s*\[[^]]*\]' | sed 's/"compliance_issues":\s*\[//' | sed 's/\]$//' | tr ',' '\n' | tr -d '"' | grep -v '^\s*$' || echo "")
    
    if [ -n "$issues" ]; then
        echo "$issues" | while read -r line; do
            if [ -n "$line" ]; then
                echo "- ❌ $line"
            fi
        done
    else
        echo "- ✅ Проблем не обнаружено"
    fi
    
    echo ""
    
    # Рекомендации
    echo "### Рекомендации"
    echo ""
    
    local recs
    recs=$(echo "$SPEC_COMPLIANCE_DATA" | grep -o '"recommendations":\s*\[[^]]*\]' | sed 's/"recommendations":\s*\[//' | sed 's/\]$//' | tr ',' '\n' | tr -d '"' | grep -v '^\s*$' || echo "")
    
    if [ -n "$recs" ]; then
        echo "$recs" | while read -r line; do
            if [ -n "$line" ]; then
                echo "- 💡 $line"
            fi
        done
    else
        echo "- ✅ Рекомендаций нет"
    fi
    
    echo ""
}

# Генерация секции Agent Interaction
generate_agent_interaction_section() {
    cat << EOF
## Agent Interaction

EOF

    local score
    score=$(get_json_value "$AGENT_INTERACTION_DATA" "score")
    local grade
    grade=$(get_json_value "$AGENT_INTERACTION_DATA" "grade")
    
    echo "**Score**: ${score:-N/A}/100 (${grade:-N/A})"
    echo ""
    
    # Паттерны
    echo "### Паттерны"
    echo ""
    
    local patterns
    patterns=$(echo "$AGENT_INTERACTION_DATA" | grep -o '"patterns":\s*\[[^]]*\]' | sed 's/"patterns":\s*\[//' | sed 's/\]$//' | tr ',' '\n' | tr -d '"' | grep -v '^\s*$' || echo "")
    
    if [ -n "$patterns" ]; then
        echo "$patterns" | while read -r line; do
            if [ -n "$line" ]; then
                echo "- 📊 $line"
            fi
        done
    else
        echo "- ℹ️ Паттернов не обнаружено"
    fi
    
    echo ""
    
    # Аномалии
    echo "### Аномалии"
    echo ""
    
    local anomalies
    anomalies=$(echo "$AGENT_INTERACTION_DATA" | grep -o '"anomalies":\s*\[[^]]*\]' | sed 's/"anomalies":\s*\[//' | sed 's/\]$//' | tr ',' '\n' | tr -d '"' | grep -v '^\s*$' || echo "")
    
    if [ -n "$anomalies" ]; then
        echo "$anomalies" | while read -r line; do
            if [ -n "$line" ]; then
                echo "- ⚠️ $line"
            fi
        done
    else
        echo "- ✅ Аномалий не обнаружено"
    fi
    
    echo ""
    
    # Эффективность
    echo "### Эффективность"
    echo ""
    
    local avg_time
    avg_time=$(get_json_value "$AGENT_INTERACTION_DATA" "avg_response_time_ms")
    local total_tokens
    total_tokens=$(get_json_value "$AGENT_INTERACTION_DATA" "total_tokens")
    
    echo "| Метрика | Значение |"
    echo "|---------|----------|"
    echo "| Среднее время ответа | ${avg_time:-N/A} мс |"
    echo "| Всего токенов | ${total_tokens:-N/A} |"
    echo ""
}

# Генерация секции Logic Consistency
generate_logic_consistency_section() {
    cat << EOF
## Logic Consistency

EOF

    local score
    score=$(get_json_value "$LOGIC_CONSISTENCY_DATA" "score")
    local grade
    grade=$(get_json_value "$LOGIC_CONSISTENCY_DATA" "grade")
    
    echo "**Score**: ${score:-N/A}/100 (${grade:-N/A})"
    echo ""
    
    # Противоречия
    echo "### Противоречия"
    echo ""
    
    local contradictions
    contradictions=$(echo "$LOGIC_CONSISTENCY_DATA" | grep -o '"contradictions":\s*\[[^]]*\]' | sed 's/"contradictions":\s*\[//' | sed 's/\]$//' | tr ',' '\n' | tr -d '"' | grep -v '^\s*$' || echo "")
    
    if [ -n "$contradictions" ]; then
        echo "$contradictions" | while read -r line; do
            if [ -n "$line" ]; then
                echo "- ❌ $line"
            fi
        done
    else
        echo "- ✅ Противоречий не обнаружено"
    fi
    
    echo ""
    
    # Несостыковки путей
    echo "### Несостыковки путей"
    echo ""
    
    local paths
    paths=$(echo "$LOGIC_CONSISTENCY_DATA" | grep -o '"path_mismatches":\s*\[[^]]*\]' | sed 's/"path_mismatches":\s*\[//' | sed 's/\]$//' | tr ',' '\n' | tr -d '"' | grep -v '^\s*$' || echo "")
    
    if [ -n "$paths" ]; then
        echo "$paths" | while read -r line; do
            if [ -n "$line" ]; then
                echo "- ⚠️ $line"
            fi
        done
    else
        echo "- ✅ Несостыковок не обнаружено"
    fi
    
    echo ""
}

# Генерация секции Quality Trends
generate_quality_trends_section() {
    cat << EOF
## Quality Trends

EOF

    local score
    score=$(get_json_value "$QUALITY_TRENDS_DATA" "score")
    local grade
    grade=$(get_json_value "$QUALITY_TRENDS_DATA" "grade")
    
    echo "**Score**: ${score:-N/A}/100 (${grade:-N/A})"
    echo ""
    
    # Метрики
    echo "### Метрики"
    echo ""
    
    local current_score
    current_score=$(get_json_value "$QUALITY_TRENDS_DATA" "current_score")
    local previous_score
    previous_score=$(get_json_value "$QUALITY_TRENDS_DATA" "previous_score")
    local score_change
    score_change=$(get_json_value "$QUALITY_TRENDS_DATA" "score_change")
    
    echo "| Метрика | Значение |"
    echo "|---------|----------|"
    echo "| Текущий score | ${current_score:-N/A} |"
    echo "| Предыдущий score | ${previous_score:-N/A} |"
    echo "| Изменение | ${score_change:-0} |"
    echo ""
    
    # Тренды
    echo "### Тренды"
    echo ""
    
    local trends
    trends=$(echo "$QUALITY_TRENDS_DATA" | grep -o '"trends":\s*\[[^]]*\]' | sed 's/"trends":\s*\[//' | sed 's/\]$//' | tr ',' '\n' | tr -d '"' | grep -v '^\s*$' || echo "")
    
    if [ -n "$trends" ]; then
        echo "$trends" | while read -r line; do
            if [ -n "$line" ]; then
                echo "- 📈 $line"
            fi
        done
    else
        echo "- ℹ️ Трендов не обнаружено"
    fi
    
    echo ""
    
    # Прогнозы
    echo "### Прогнозы"
    echo ""
    
    local predictions
    predictions=$(echo "$QUALITY_TRENDS_DATA" | grep -o '"predictions":\s*\[[^]]*\]' | sed 's/"predictions":\s*\[//' | sed 's/\]$//' | tr ',' '\n' | tr -d '"' | grep -v '^\s*$' || echo "")
    
    if [ -n "$predictions" ]; then
        echo "$predictions" | while read -r line; do
            if [ -n "$line" ]; then
                echo "- 🔮 $line"
            fi
        done
    else
        echo "- ℹ️ Прогнозов нет"
    fi
    
    echo ""
}

# Генерация Action Items
generate_action_items() {
    cat << EOF
## Action Items

EOF

    echo "### Priority 0 (Критичное)"
    echo ""
    
    local p0_count=0
    
    # Сбор критических проблем из всех отчетов
    local all_issues=""
    all_issues+=$(echo "$GIT_WORKFLOW_DATA" | grep -o '"violations":\s*\[[^]]*\]' | sed 's/"violations":\s*\[//' | sed 's/\]$//' || echo "")
    all_issues+=$'\n'
    all_issues+=$(echo "$SPEC_COMPLIANCE_DATA" | grep -o '"compliance_issues":\s*\[[^]]*\]' | sed 's/"compliance_issues":\s*\[//' | sed 's/\]$//' || echo "")
    all_issues+=$'\n'
    all_issues+=$(echo "$AGENT_INTERACTION_DATA" | grep -o '"anomalies":\s*\[[^]]*\]' | sed 's/"anomalies":\s*\[//' | sed 's/\]$//' || echo "")
    all_issues+=$'\n'
    all_issues+=$(echo "$LOGIC_CONSISTENCY_DATA" | grep -o '"contradictions":\s*\[[^]]*\]' | sed 's/"contradictions":\s*\[//' | sed 's/\]$//' || echo "")
    
    local critical_items
    critical_items=$(echo "$all_issues" | tr ',' '\n' | tr -d '"' | grep -v '^\s*$' | head -5 || echo "")
    
    if [ -n "$critical_items" ]; then
        echo "$critical_items" | while read -r line; do
            if [ -n "$line" ]; then
                echo "- [ ] $line"
                ((p0_count++))
            fi
        done
    else
        echo "- ✅ Критических проблем нет"
    fi
    
    echo ""
    echo "### Priority 1 (Важное)"
    echo ""
    
    # Сбор предупреждений
    local warnings=""
    warnings+=$(echo "$GIT_WORKFLOW_DATA" | grep -o '"warnings":\s*\[[^]]*\]' | sed 's/"warnings":\s*\[//' | sed 's/\]$//' || echo "")
    warnings+=$'\n'
    warnings+=$(echo "$LOGIC_CONSISTENCY_DATA" | grep -o '"path_mismatches":\s*\[[^]]*\]' | sed 's/"path_mismatches":\s*\[//' | sed 's/\]$//' || echo "")
    
    local p1_items
    p1_items=$(echo "$warnings" | tr ',' '\n' | tr -d '"' | grep -v '^\s*$' | head -5 || echo "")
    
    if [ -n "$p1_items" ]; then
        echo "$p1_items" | while read -r line; do
            if [ -n "$line" ]; then
                echo "- [ ] $line"
            fi
        done
    else
        echo "- ✅ Важных проблем нет"
    fi
    
    echo ""
    echo "### Priority 2 (Желательное)"
    echo ""
    
    # Сбор рекомендаций
    local all_recs=""
    all_recs+=$(echo "$GIT_WORKFLOW_DATA" | grep -o '"recommendations":\s*\[[^]]*\]' | sed 's/"recommendations":\s*\[//' | sed 's/\]$//' || echo "")
    all_recs+=$'\n'
    all_recs+=$(echo "$SPEC_COMPLIANCE_DATA" | grep -o '"recommendations":\s*\[[^]]*\]' | sed 's/"recommendations":\s*\[//' | sed 's/\]$//' || echo "")
    all_recs+=$'\n'
    all_recs+=$(echo "$AGENT_INTERACTION_DATA" | grep -o '"recommendations":\s*\[[^]]*\]' | sed 's/"recommendations":\s*\[//' | sed 's/\]$//' || echo "")
    all_recs+=$'\n'
    all_recs+=$(echo "$LOGIC_CONSISTENCY_DATA" | grep -o '"recommendations":\s*\[[^]]*\]' | sed 's/"recommendations":\s*\[//' | sed 's/\]$//' || echo "")
    all_recs+=$'\n'
    all_recs+=$(echo "$QUALITY_TRENDS_DATA" | grep -o '"recommendations":\s*\[[^]]*\]' | sed 's/"recommendations":\s*\[//' | sed 's/\]$//' || echo "")
    
    local p2_items
    p2_items=$(echo "$all_recs" | tr ',' '\n' | tr -d '"' | grep -v '^\s*$' | head -10 || echo "")
    
    if [ -n "$p2_items" ]; then
        echo "$p2_items" | while read -r line; do
            if [ -n "$line" ]; then
                echo "- [ ] $line"
            fi
        done
    else
        echo "- ✅ Рекомендаций нет"
    fi
    
    echo ""
}

# Генерация полного отчета
generate_full_report() {
    log_info "Генерация полного отчета..."
    
    cat > "$REPORT_FILE" << EOF
# Feedback Report: $TIMESTAMP

**Сгенерировано**: $(date '+%Y-%m-%d %H:%M:%S')
**Проект**: $(basename "$PROJECT_ROOT" 2>/dev/null || echo "Unknown")
**Версия системы**: 1.0.0

$(generate_executive_summary)
$(generate_git_workflow_section)
$(generate_spec_compliance_section)
$(generate_agent_interaction_section)
$(generate_logic_consistency_section)
$(generate_quality_trends_section)
$(generate_action_items)
---
*Отчет сгенерирован автоматически системой Feedback System v1.0.0*
EOF
    
    log_success "Отчет сохранен: $REPORT_FILE"
}

# Показать помощь
show_help() {
    cat << EOF
Generate Feedback Report v1.0.0

Назначение: Генерация итогового отчета из JSON анализаторов

Использование:
  $(basename "$0") [OPTIONS]

Опции:
  -h, --help          Показать эту справку
  -v, --verbose       Подробный вывод
  -q, --quiet         Тихий режим
  -r, --reports-dir   Директория с отчетами (по умолчанию: ../reports)
  -o, --output        Директория для вывода (по умолчанию: ../reports)

Примеры:
  $(basename "$0")                              # Запуск с настройками по умолчанию
  $(basename "$0") -r /path/to/reports          # Указать директорию отчетов
  $(basename "$0") -o /tmp/output               # Вывод в другую директорию

Вход:
  JSON файлы от 5 анализаторов

Выход:
  Markdown отчет со всеми нарушениями и рекомендациями
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
        echo "  Generate Feedback Report v1.0.0"
        echo "========================================"
        echo ""
    fi
    
    load_json_data
    generate_full_report
    
    if [ "$QUIET" = false ]; then
        echo ""
        echo "========================================"
        echo "  Отчет сгенерирован"
        echo "========================================"
        echo ""
        echo "Файл отчета: $REPORT_FILE"
    fi
}

main
