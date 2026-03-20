#!/bin/bash
#
# Quality Trends Analyzer
# Назначение: Анализ трендов качества
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
HISTORY_DIR="${HISTORY_DIR:-$SCRIPT_DIR/../reports}"

# Переменные для сбора данных
declare -a QUALITY_METRICS=()
declare -a TRENDS=()
declare -a PREDICTIONS=()
declare -a FIX_STATISTICS=()
declare -a RECOMMENDATIONS=()

# Метрики
CURRENT_SCORE=0
PREVIOUS_SCORE=0
SCORE_CHANGE=0
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0
BLOCKING_FAILURES=0
NON_BLOCKING_FAILURES=0
AVG_FIX_TIME=0
TOTAL_FIXES=0

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

# Сбор метрик Quality Gates
collect_quality_metrics() {
    log_info "Сбор метрик Quality Gates..."
    
    # Поиск последних отчетов анализаторов
    local latest_reports
    latest_reports=$(find "$HISTORY_DIR" -name "*-analysis-*.json" -type f 2>/dev/null | sort -r | head -10)
    
    if [ -z "$latest_reports" ]; then
        log_warning "Отчеты анализаторов не найдены"
        RECOMMENDATIONS+=("Запустите анализаторы для сбора метрик качества")
        return 1
    fi
    
    local total_score=0
    local report_count=0
    
    while IFS= read -r report; do
        if [ -f "$report" ]; then
            # Извлечение score из JSON
            local score
            score=$(grep -o '"score":\s*[0-9]\+' "$report" 2>/dev/null | grep -o '[0-9]\+' || echo "0")
            
            if [ "$score" -gt 0 ]; then
                total_score=$((total_score + score))
                ((report_count++)) || true
                
                # Извлечение типа анализатора
                local analyzer
                analyzer=$(grep -o '"analyzer":\s*"[^"]*"' "$report" 2>/dev/null | cut -d'"' -f4 || echo "unknown")
                
                QUALITY_METRICS+=("$analyzer: $score")
            fi
            
            # Подсчет проверок
            local checks
            checks=$(grep -oE '"(violations|warnings|errors|anomalies|contradictions)":\s*\[' "$report" 2>/dev/null | wc -l || echo "0")
            TOTAL_CHECKS=$((TOTAL_CHECKS + checks))
        fi
    done <<< "$latest_reports"
    
    if [ "$report_count" -gt 0 ]; then
        CURRENT_SCORE=$((total_score / report_count))
        log_success "Текущий средний score: $CURRENT_SCORE/100"
    fi
    
    # Поиск предыдущих отчетов (старше 7 дней)
    local old_reports
    old_reports=$(find "$HISTORY_DIR" -name "*-analysis-*.json" -type f -mtime +7 2>/dev/null | sort -r | head -5)
    
    if [ -n "$old_reports" ]; then
        local old_total=0
        local old_count=0
        
        while IFS= read -r report; do
            if [ -f "$report" ]; then
                local score
                score=$(grep -o '"score":\s*[0-9]\+' "$report" 2>/dev/null | grep -o '[0-9]\+' || echo "0")
                
                if [ "$score" -gt 0 ]; then
                    old_total=$((old_total + score))
                    ((old_count++)) || true
                fi
            fi
        done <<< "$old_reports"
        
        if [ "$old_count" -gt 0 ]; then
            PREVIOUS_SCORE=$((old_total / old_count))
            SCORE_CHANGE=$((CURRENT_SCORE - PREVIOUS_SCORE))
        fi
    fi
}

# Анализ трендов по времени
analyze_trends() {
    log_info "Анализ трендов..."
    
    # Группировка отчетов по неделям
    declare -A weekly_scores
    
    while IFS= read -r report; do
        if [ -f "$report" ]; then
            # Получение даты файла
            local file_date
            file_date=$(stat -c %Y "$report" 2>/dev/null || echo "0")
            local week_num
            week_num=$((file_date / 604800))  # Номер недели
            
            local score
            score=$(grep -o '"score":\s*[0-9]\+' "$report" 2>/dev/null | grep -o '[0-9]\+' || echo "0")
            
            if [ "$score" -gt 0 ]; then
                if [ -z "${weekly_scores[$week_num]:-}" ]; then
                    weekly_scores[$week_num]=0
                fi
                weekly_scores[$week_num]=$((${weekly_scores[$week_num]} + score))
            fi
        fi
    done < <(find "$HISTORY_DIR" -name "*-analysis-*.json" -type f 2>/dev/null | head -50)
    
    # Анализ тренда
    local weeks=("${!weekly_scores[@]}")
    if [ "${#weeks[@]}" -ge 2 ]; then
        # Сортировка недель
        IFS=$'\n' sorted_weeks=($(sort -n <<< "${weeks[*]}")); unset IFS
        
        local first_week="${sorted_weeks[0]}"
        local last_week="${sorted_weeks[-1]}"
        
        local first_avg=$((${weekly_scores[$first_week]} / 5))  # Примерно 5 отчетов в неделю
        local last_avg=$((${weekly_scores[$last_week]} / 5))
        
        local trend=$((last_avg - first_avg))
        
        if [ "$trend" -gt 5 ]; then
            TRENDS+=("Положительный тренд: +$trend пунктов за период")
        elif [ "$trend" -lt -5 ]; then
            TRENDS+=("Отрицательный тренд: $trend пунктов за период")
            RECOMMENDATIONS+=("Обратите внимание на ухудшение качества")
        else
            TRENDS+=("Стабильное качество: изменение $trend пунктов")
        fi
    else
        TRENDS+=("Недостаточно данных для анализа трендов")
    fi
    
    # Анализ по типам анализаторов
    declare -A analyzer_scores
    declare -A analyzer_counts
    
    while IFS= read -r report; do
        if [ -f "$report" ]; then
            local analyzer
            analyzer=$(grep -o '"analyzer":\s*"[^"]*"' "$report" 2>/dev/null | cut -d'"' -f4 || echo "unknown")
            
            local score
            score=$(grep -o '"score":\s*[0-9]\+' "$report" 2>/dev/null | grep -o '[0-9]\+' || echo "0")
            
            if [ "$score" -gt 0 ]; then
                if [ -z "${analyzer_scores[$analyzer]:-}" ]; then
                    analyzer_scores[$analyzer]=0
                    analyzer_counts[$analyzer]=0
                fi
                analyzer_scores[$analyzer]=$((${analyzer_scores[$analyzer]} + score))
                analyzer_counts[$analyzer]=$((${analyzer_counts[$analyzer]} + 1))
            fi
        fi
    done < <(find "$HISTORY_DIR" -name "*-analysis-*.json" -type f 2>/dev/null | head -50)
    
    # Определение лучшего и худшего анализатора
    local best_analyzer=""
    local best_score=0
    local worst_analyzer=""
    local worst_score=100
    
    for analyzer in "${!analyzer_scores[@]}"; do
        local avg=$((${analyzer_scores[$analyzer]} / ${analyzer_counts[$analyzer]}))
        
        if [ "$avg" -gt "$best_score" ]; then
            best_score=$avg
            best_analyzer=$analyzer
        fi
        
        if [ "$avg" -lt "$worst_score" ]; then
            worst_score=$avg
            worst_analyzer=$analyzer
        fi
    done
    
    if [ -n "$best_analyzer" ]; then
        TRENDS+=("Лучшая область: $best_analyzer (средний score: $best_score)")
    fi
    
    if [ -n "$worst_analyzer" ]; then
        TRENDS+=("Требует внимания: $worst_analyzer (средний score: $worst_score)")
        RECOMMENDATIONS+=("Сфокусируйтесь на улучшении $worst_analyzer")
    fi
}

# Прогнозирование проблем
predict_issues() {
    log_info "Прогнозирование проблем..."
    
    # Прогноз на основе текущего тренда
    if [ "$SCORE_CHANGE" -lt -10 ]; then
        PREDICTIONS+=("Внимание: При сохранении тренда score упадет ниже 60 в течение 7 дней")
        RECOMMENDATIONS+=("Срочно проведите анализ проблемных областей")
    elif [ "$SCORE_CHANGE" -lt 0 ]; then
        PREDICTIONS+=("Осторожно: Наблюдается небольшое ухудшение качества")
    elif [ "$SCORE_CHANGE" -gt 10 ]; then
        PREDICTIONS+=("Прогноз: Качество улучшается, ожидаемый score через неделю: $((CURRENT_SCORE + SCORE_CHANGE))")
    fi
    
    # Прогноз на основе частоты ошибок
    local recent_failures=0
    while IFS= read -r report; do
        if [ -f "$report" ]; then
            local failures
            failures=$(grep -oE '"(violations_count|errors_count|anomalies_count)":\s*[0-9]\+' "$report" 2>/dev/null | grep -o '[0-9]\+' || echo "0")
            recent_failures=$((recent_failures + failures))
        fi
    done < <(find "$HISTORY_DIR" -name "*-analysis-*.json" -type f -mtime -3 2>/dev/null | head -10)
    
    if [ "$recent_failures" -gt 20 ]; then
        PREDICTIONS+=("Высокая частота ошибок: $recent_failures за 3 дня")
        RECOMMENDATIONS+=("Проведите код-ревью и рефакторинг проблемных областей")
    fi
    
    # Прогноз технической задолженности
    if [ "$CURRENT_SCORE" -lt 70 ]; then
        PREDICTIONS+=("Техническая задолженность: Требуется рефакторинг")
        RECOMMENDATIONS+=("Запланируйте спринт технической задолженности")
    fi
}

# Статистика исправлений
analyze_fix_statistics() {
    log_info "Анализ статистики исправлений..."
    
    # Поиск коммитов с исправлениями
    if [ -d "$PROJECT_ROOT/.git" ]; then
        # Коммиты с fix/исправл
        local fix_commits
        fix_commits=$(git log --oneline --all --grep="fix\|исправ\|bug\|error" 2>/dev/null | wc -l || echo "0")
        TOTAL_FIXES=$fix_commits
        
        if [ "$fix_commits" -gt 0 ]; then
            FIX_STATISTICS+=("Всего исправлений: $fix_commits")
            
            # Коммиты за последнюю неделю
            local week_fixes
            week_fixes=$(git log --oneline --since="1 week ago" --grep="fix\|исправ" 2>/dev/null | wc -l || echo "0")
            
            if [ "$week_fixes" -gt 5 ]; then
                FIX_STATISTICS+=("Исправлений за неделю: $week_fixes (высокая активность)")
                RECOMMENDATIONS+=("Проанализируйте корневые причины частых исправлений")
            elif [ "$week_fixes" -gt 0 ]; then
                FIX_STATISTICS+=("Исправлений за неделю: $week_fixes")
            fi
            
            # Среднее время между исправлениями
            if [ "$fix_commits" -gt 1 ]; then
                local first_commit_date
                first_commit_date=$(git log --reverse --format="%ai" --grep="fix" 2>/dev/null | head -1 | cut -d' ' -f1 || echo "")
                local last_commit_date
                last_commit_date=$(git log --format="%ai" --grep="fix" 2>/dev/null | head -1 | cut -d' ' -f1 || echo "")
                
                if [ -n "$first_commit_date" ] && [ -n "$last_commit_date" ]; then
                    local first_ts
                    first_ts=$(date -d "$first_commit_date" +%s 2>/dev/null || echo "0")
                    local last_ts
                    last_ts=$(date -d "$last_commit_date" +%s 2>/dev/null || echo "0")
                    
                    if [ "$last_ts" -gt "$first_ts" ] && [ "$fix_commits" -gt 1 ]; then
                        AVG_FIX_TIME=$(( (last_ts - first_ts) / (fix_commits - 1) / 3600 ))
                        FIX_STATISTICS+=("Среднее время между исправлениями: ${AVG_FIX_TIME}ч")
                    fi
                fi
            fi
        fi
    fi
    
    # Анализ типов исправлений
    if [ -d "$PROJECT_ROOT/.git" ]; then
        local hotfix_commits
        hotfix_commits=$(git log --oneline --all --grep="hotfix\|critical\|urgent" 2>/dev/null | wc -l || echo "0")
        
        if [ "$hotfix_commits" -gt 0 ]; then
            FIX_STATISTICS+=("Критических исправлений: $hotfix_commits")
            
            if [ "$hotfix_commits" -gt "$((TOTAL_FIXES / 4))" ]; then
                RECOMMENDATIONS+=("Высокий процент критических исправлений - улучшите тестирование")
            fi
        fi
    fi
}

# Подсчет проверок
count_checks() {
    log_info "Подсчет проверок..."
    
    # Поиск последних отчетов
    local latest_git="$HISTORY_DIR"/git-workflow-analysis-*.json
    local latest_spec="$HISTORY_DIR"/spec-compliance-analysis-*.json
    local latest_agent="$HISTORY_DIR"/agent-interaction-analysis-*.json
    local latest_logic="$HISTORY_DIR"/logic-consistency-analysis-*.json
    local latest_quality="$HISTORY_DIR"/quality-trends-analysis-*.json
    
    for report in $latest_git $latest_spec $latest_agent $latest_logic $latest_quality; do
        if [ -f "$report" ]; then
            local violations warnings errors
            violations=$(grep -o '"violations":\s*\[[^]]*\]' "$report" 2>/dev/null | grep -o '[0-9]\+' | head -1 || echo "0")
            warnings=$(grep -o '"warnings":\s*\[[^]]*\]' "$report" 2>/dev/null | grep -o '[0-9]\+' | head -1 || echo "0")
            errors=$(grep -o '"errors":\s*\[[^]]*\]' "$report" 2>/dev/null | grep -o '[0-9]\+' | head -1 || echo "0")
            
            # Подсчет элементов в массивах
            local v_count=0 w_count=0 e_count=0
            
            if [ -n "$violations" ] && [ "$violations" != "0" ]; then
                v_count=$(grep -o '"violations":\s*\[' "$report" 2>/dev/null | wc -l || echo "0")
            fi
            
            PASSED_CHECKS=$((PASSED_CHECKS + 1))
            
            if [ "$v_count" -gt 0 ] || [ "$violations" -gt 0 ]; then
                ((FAILED_CHECKS++)) || true
                ((BLOCKING_FAILURES++)) || true
            fi
        fi
    done
    
    TOTAL_CHECKS=$((PASSED_CHECKS + FAILED_CHECKS))
}

# Расчет общего score
calculate_score() {
    # Score уже рассчитан из отчетов
    echo "$CURRENT_SCORE"
}

# Генерация JSON отчета
generate_json_report() {
    local score
    score=$(calculate_score)
    
    # Формирование массивов JSON
    local metrics_json="[]"
    local trends_json="[]"
    local predictions_json="[]"
    local fixes_json="[]"
    local recommendations_json="[]"
    
    if [ ${#QUALITY_METRICS[@]} -gt 0 ]; then
        metrics_json=$(printf '%s\n' "${QUALITY_METRICS[@]}" | jq -R . | jq -s .)
    fi
    
    if [ ${#TRENDS[@]} -gt 0 ]; then
        trends_json=$(printf '%s\n' "${TRENDS[@]}" | jq -R . | jq -s .)
    fi
    
    if [ ${#PREDICTIONS[@]} -gt 0 ]; then
        predictions_json=$(printf '%s\n' "${PREDICTIONS[@]}" | jq -R . | jq -s .)
    fi
    
    if [ ${#FIX_STATISTICS[@]} -gt 0 ]; then
        fixes_json=$(printf '%s\n' "${FIX_STATISTICS[@]}" | jq -R . | jq -s .)
    fi
    
    if [ ${#RECOMMENDATIONS[@]} -gt 0 ]; then
        recommendations_json=$(printf '%s\n' "${RECOMMENDATIONS[@]}" | jq -R . | jq -s .)
    fi
    
    # Создание JSON файла
    cat > "$OUTPUT_DIR/quality-trends-analysis-$TIMESTAMP.json" << EOF
{
  "timestamp": "$TIMESTAMP",
  "status": "completed",
  "analyzer": "quality-trends-analyzer",
  "version": "1.0.0",
  "project_root": "$PROJECT_ROOT",
  "quality_metrics": $metrics_json,
  "trends": $trends_json,
  "predictions": $predictions_json,
  "fix_statistics": $fixes_json,
  "recommendations": $recommendations_json,
  "metrics": {
    "current_score": $CURRENT_SCORE,
    "previous_score": $PREVIOUS_SCORE,
    "score_change": $SCORE_CHANGE,
    "total_checks": $TOTAL_CHECKS,
    "passed_checks": $PASSED_CHECKS,
    "failed_checks": $FAILED_CHECKS,
    "blocking_failures": $BLOCKING_FAILURES,
    "non_blocking_failures": $NON_BLOCKING_FAILURES,
    "avg_fix_time_hours": $AVG_FIX_TIME,
    "total_fixes": $TOTAL_FIXES
  },
  "score": $score,
  "grade": "$(if [ $score -ge 90 ]; then echo "A"; elif [ $score -ge 80 ]; then echo "B"; elif [ $score -ge 70 ]; then echo "C"; elif [ $score -ge 60 ]; then echo "D"; else echo "F"; fi)"
}
EOF
    
    log_success "Отчет сохранен: $OUTPUT_DIR/quality-trends-analysis-$TIMESTAMP.json"
}

# Показать помощь
show_help() {
    cat << EOF
Quality Trends Analyzer v1.0.0

Назначение: Анализ трендов качества

Использование:
  $(basename "$0") [OPTIONS]

Опции:
  -h, --help          Показать эту справку
  -v, --verbose       Подробный вывод
  -q, --quiet         Тихий режим (только JSON)
  -o, --output        Директория для вывода (по умолчанию: ../reports)
  -H, --history-dir   Директория истории отчетов (по умолчанию: ../reports)

Примеры:
  $(basename "$0")                              # Запуск с настройками по умолчанию
  $(basename "$0") -H /path/to/history          # Указать директорию истории
  $(basename "$0") -q                           # Тихий режим

Проверки:
  1. Метрики Quality Gates
  2. Тренды по времени
  3. Прогнозы проблем
  4. Статистика исправлений

Выход:
  JSON с трендами
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
        -H|--history-dir)
            HISTORY_DIR="$2"
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
        echo "  Quality Trends Analyzer v1.0.0"
        echo "========================================"
        echo ""
    fi
    
    collect_quality_metrics
    analyze_trends
    predict_issues
    analyze_fix_statistics
    count_checks
    
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
        
        if [ "$SCORE_CHANGE" -ne 0 ]; then
            if [ "$SCORE_CHANGE" -gt 0 ]; then
                log_success "Изменение: +$SCORE_CHANGE (улучшение)"
            else
                log_warning "Изменение: $SCORE_CHANGE (ухудшение)"
            fi
        fi
        
        echo ""
        echo "Метрики качества: ${#QUALITY_METRICS[@]}"
        echo "Тренды: ${#TRENDS[@]}"
        echo "Прогнозы: ${#PREDICTIONS[@]}"
        echo "Статистика исправлений: ${#FIX_STATISTICS[@]}"
        echo "Рекомендации: ${#RECOMMENDATIONS[@]}"
    fi
}

main
