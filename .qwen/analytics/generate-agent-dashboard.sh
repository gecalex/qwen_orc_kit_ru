#!/bin/bash
#
# Generate Agent Dashboard - Генерация дашборда с метриками агентов
# Назначение: Визуализация метрик, тренды, heatmap нагрузки, рекомендации
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

# Флаги
VERBOSE=false
QUIET=false
OUTPUT_FORMAT="html"  # html, md, both
OUTPUT_DIR="$REPORTS_DIR"
LOG_FILE="$LOGS_DIR/agent-calls.log"
ANALYSIS_FILE=""

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
${WHITE}Generate Agent Dashboard v1.0.0${NC}

Генерация дашборда с метриками агентов

${WHITE}Использование:${NC}
  $(basename "$0") [OPTIONS]

${WHITE}Опции:${NC}
  -h, --help              Показать эту справку
  -v, --verbose           Подробный вывод
  -q, --quiet             Тихий режим
  -o, --output DIR        Директория для вывода
  -f, --format FORMAT     Формат: html, md, both (по умолчанию: html)
  -l, --log FILE          Файл логов
  -a, --analysis FILE     JSON файл анализа (опционально)

${WHITE}Примеры:${NC}
  $(basename "$0")                                    # HTML дашборд
  $(basename "$0") -f md                              # Markdown дашборд
  $(basename "$0") -f both                            # Оба формата
  $(basename "$0") -a analysis.json                   # Использовать готовый анализ

${WHITE}Выход:${NC}
  - HTML дашборд с визуализацией
  - Markdown версия (опционально)
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

# Запуск анализатора если нужно
run_analyzer_if_needed() {
    if [ -z "$ANALYSIS_FILE" ] || [ ! -f "$ANALYSIS_FILE" ]; then
        log_step "Запуск agent-call-analyzer.sh для получения данных..."
        
        local analyzer_script="$ANALYTICS_DIR/agent-call-analyzer.sh"
        if [ -x "$analyzer_script" ]; then
            "$analyzer_script" -q -o "$OUTPUT_DIR" -l "$LOG_FILE" > /dev/null 2>&1
            
            # Поиск последнего JSON файла
            ANALYSIS_FILE=$(ls -t "$OUTPUT_DIR"/agent-call-analysis-*.json 2>/dev/null | head -1)
            
            if [ -n "$ANALYSIS_FILE" ]; then
                log_success "Анализ найден: $ANALYSIS_FILE"
            else
                log_error "Не удалось найти файл анализа"
                return 1
            fi
        else
            log_error "agent-call-analyzer.sh не найден или не исполняемый"
            return 1
        fi
    else
        log_info "Используется существующий анализ: $ANALYSIS_FILE"
    fi
}

# Чтение данных анализа
read_analysis_data() {
    log_step "Чтение данных анализа..."
    
    # Извлечение данных из JSON
    TOTAL_CALLS=$(jq -r '.summary.total_calls' "$ANALYSIS_FILE")
    TOTAL_SUCCESS=$(jq -r '.summary.total_success' "$ANALYSIS_FILE")
    TOTAL_FAILED=$(jq -r '.summary.total_failed' "$ANALYSIS_FILE")
    SUCCESS_RATE=$(jq -r '.summary.success_rate' "$ANALYSIS_FILE")
    AVG_TIME=$(jq -r '.summary.average_time_seconds' "$ANALYSIS_FILE")
    TOTAL_TIME=$(jq -r '.summary.total_time_seconds' "$ANALYSIS_FILE")
    TOTAL_TOKENS=$(jq -r '.summary.total_tokens' "$ANALYSIS_FILE")
    PEAK_HOUR=$(jq -r '.summary.peak_hour' "$ANALYSIS_FILE")
    
    # Агенты
    AGENTS_JSON=$(jq -r '.agents' "$ANALYSIS_FILE")
    
    # Аномалии
    ANOMALIES_JSON=$(jq -r '.anomalies' "$ANALYSIS_FILE")
    
    log_success "Данные загружены"
}

# Генерация heatmap нагрузки
generate_heatmap() {
    log_step "Генерация heatmap нагрузки..."
    
    local heatmap=""
    
    # Чтение логов для почасовой статистики
    declare -A HOUR_CALLS
    
    while IFS='|' read -r timestamp rest; do
        if [[ "$rest" == *"started"* ]]; then
            local hour=$(echo "$timestamp" | cut -d'T' -f2 | cut -d':' -f1)
            HOUR_CALLS["$hour"]=$((${HOUR_CALLS["$hour"]:-0} + 1))
        fi
    done < "$LOG_FILE"
    
    # Генерация heatmap
    for h in $(seq -w 0 23); do
        local count=${HOUR_CALLS["$h"]:-0}
        local bar=""
        local hour_num=$((10#$h))  # Remove leading zero for arithmetic
        
        if [ "$count" -gt 0 ]; then
            # Определение цвета на основе количества
            if [ "$count" -ge 10 ]; then
                bar="🔴"
            elif [ "$count" -ge 5 ]; then
                bar="🟠"
            elif [ "$count" -ge 2 ]; then
                bar="🟡"
            else
                bar="🟢"
            fi
        else
            bar="⚪"
        fi

        heatmap+="$h:00 $bar ($count)  "

        if [ $((hour_num % 6)) -eq 5 ]; then
            heatmap+=$'\n'
        fi
    done

    echo "$heatmap"
}

# Генерация топ проблемных агентов
generate_top_problematic() {
    log_step "Генерация топ проблемных агентов..."
    
    local problematic=""

    # Сортировка агентов по количеству ошибок
    local sorted=$(echo "$AGENTS_JSON" | jq -r 'to_entries | sort_by(-.value.failed) | .[0:5] | .[] | "\(.key):\(.value.failed) errors, \(.value.success_rate)% success"')

    while IFS= read -r line; do
        if [ -n "$line" ]; then
            local agent=$(echo "$line" | cut -d':' -f1)
            local errors=$(echo "$line" | cut -d':' -f2 | cut -d' ' -f1)
            local rate=$(echo "$line" | cut -d':' -f3 | cut -d' ' -f1 | tr -d '%')
            
            # Проверка на пустые значения
            errors=${errors:-0}
            rate=${rate:-0}

            if [ "$errors" -gt 0 ] 2>/dev/null || [ "$rate" -lt 90 ] 2>/dev/null; then
                problematic+="- **$agent**: $errors ошибок, ${rate}% успех"$'\n'
            fi
        fi
    done <<< "$sorted"

    if [ -z "$problematic" ]; then
        problematic="✅ Нет проблемных агентов"
    fi

    echo "$problematic"
}

# Генерация рекомендаций
generate_recommendations() {
    log_step "Генерация рекомендаций..."
    
    local recommendations=""
    local anomaly_count=$(echo "$ANOMALIES_JSON" | jq 'length')
    
    if [ "$anomaly_count" -gt 0 ]; then
        recommendations+="# Рекомендации по оптимизации"$'\n'$'\n'
        
        # Анализ аномалий
        local repeat_calls=$(echo "$ANOMALIES_JSON" | jq -r '[.[] | select(.type=="repeat_calls")] | length')
        local slow_agents=$(echo "$ANOMALIES_JSON" | jq -r '[.[] | select(.type=="slow_agent")] | length')
        
        if [ "$repeat_calls" -gt 0 ]; then
            recommendations+="## 🔁 Повторные вызовы"$'\n'
            recommendations+="Обнаружено $repeat_calls агентов с повторными вызовами."$'\n'$'\n'
            recommendations+="**Действия**:"$'\n'
            recommendations+="1. Увеличить timeout для проблемных агентов"$'\n'
            recommendations+="2. Добавить кэширование результатов"$'\n'
            recommendations+="3. Оптимизировать логику выполнения"$'\n'$'\n'
        fi
        
        if [ "$slow_agents" -gt 0 ]; then
            recommendations+="## 🐌 Медленные агенты"$'\n'
            recommendations+="Обнаружено $slow_agents агентов со средним временем >5 мин."$'\n'$'\n'
            recommendations+="**Действия**:"$'\n'
            recommendations+="1. Разделить задачи на подзадачи"$'\n'
            recommendations+="2. Добавить прогресс-логирование"$'\n'
            recommendations+="3. Рассмотреть параллельное выполнение"$'\n'$'\n'
        fi
    else
        recommendations+="✅ Система работает оптимально. Рекомендаций нет."
    fi
    
    echo "$recommendations"
}

# Генерация HTML дашборда
generate_html_dashboard() {
    log_step "Генерация HTML дашборда..."
    
    local html_file="$OUTPUT_DIR/agent-dashboard-$TIMESTAMP.html"
    local heatmap=$(generate_heatmap)
    local problematic=$(generate_top_problematic)
    local recommendations=$(generate_recommendations)
    
    # Определение статуса
    local status_class="healthy"
    local status_text="Здорова"
    if [ "$SUCCESS_RATE" -lt 70 ]; then
        status_class="critical"
        status_text="Критично"
    elif [ "$SUCCESS_RATE" -lt 90 ]; then
        status_class="warning"
        status_text="Внимание"
    fi
    
    cat > "$html_file" << HTMLEOF
<!DOCTYPE html>
<html lang="ru">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Agent Analytics Dashboard - $DATE</title>
    <style>
        :root {
            --bg-primary: #1a1a2e;
            --bg-secondary: #16213e;
            --bg-card: #0f3460;
            --text-primary: #eee;
            --text-secondary: #bbb;
            --success: #00d26a;
            --warning: #ffc107;
            --danger: #ff4757;
            --info: #3498db;
        }
        
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: var(--bg-primary);
            color: var(--text-primary);
            min-height: 100vh;
            padding: 20px;
        }
        
        .container {
            max-width: 1400px;
            margin: 0 auto;
        }
        
        header {
            text-align: center;
            margin-bottom: 30px;
            padding: 20px;
            background: var(--bg-secondary);
            border-radius: 10px;
        }
        
        header h1 {
            font-size: 2.5em;
            margin-bottom: 10px;
        }
        
        .status-badge {
            display: inline-block;
            padding: 8px 20px;
            border-radius: 20px;
            font-weight: bold;
            text-transform: uppercase;
        }
        
        .status-badge.healthy { background: var(--success); color: #000; }
        .status-badge.warning { background: var(--warning); color: #000; }
        .status-badge.critical { background: var(--danger); color: #fff; }
        
        .metrics-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 20px;
            margin-bottom: 30px;
        }
        
        .metric-card {
            background: var(--bg-card);
            padding: 20px;
            border-radius: 10px;
            text-align: center;
        }
        
        .metric-card h3 {
            color: var(--text-secondary);
            font-size: 0.9em;
            margin-bottom: 10px;
        }
        
        .metric-card .value {
            font-size: 2.5em;
            font-weight: bold;
        }
        
        .metric-card.success .value { color: var(--success); }
        .metric-card.warning .value { color: var(--warning); }
        .metric-card.danger .value { color: var(--danger); }
        .metric-card.info .value { color: var(--info); }
        
        .section {
            background: var(--bg-secondary);
            padding: 20px;
            border-radius: 10px;
            margin-bottom: 20px;
        }
        
        .section h2 {
            margin-bottom: 20px;
            padding-bottom: 10px;
            border-bottom: 2px solid var(--bg-card);
        }
        
        table {
            width: 100%;
            border-collapse: collapse;
        }
        
        th, td {
            padding: 12px;
            text-align: left;
            border-bottom: 1px solid var(--bg-card);
        }
        
        th {
            background: var(--bg-card);
            font-weight: 600;
        }
        
        tr:hover {
            background: rgba(255,255,255,0.05);
        }
        
        .heatmap {
            display: grid;
            grid-template-columns: repeat(6, 1fr);
            gap: 10px;
            font-family: monospace;
        }
        
        .heatmap-item {
            padding: 10px;
            background: var(--bg-card);
            border-radius: 5px;
            text-align: center;
        }
        
        .progress-bar {
            background: var(--bg-card);
            border-radius: 10px;
            height: 20px;
            overflow: hidden;
            margin-top: 10px;
        }
        
        .progress-fill {
            height: 100%;
            border-radius: 10px;
            transition: width 0.3s ease;
        }
        
        .progress-fill.success { background: var(--success); }
        .progress-fill.warning { background: var(--warning); }
        .progress-fill.danger { background: var(--danger); }
        
        .anomaly-item {
            background: var(--bg-card);
            padding: 15px;
            border-radius: 5px;
            margin-bottom: 10px;
            border-left: 4px solid var(--warning);
        }
        
        .recommendation-item {
            background: var(--bg-card);
            padding: 15px;
            border-radius: 5px;
            margin-bottom: 10px;
            border-left: 4px solid var(--info);
        }
        
        footer {
            text-align: center;
            padding: 20px;
            color: var(--text-secondary);
            font-size: 0.9em;
        }
    </style>
</head>
<body>
    <div class="container">
        <header>
            <h1>🤖 Agent Analytics Dashboard</h1>
            <p>Дата: $DATE | Время генерации: $TIMESTAMP</p>
            <span class="status-badge $status_class">$status_text</span>
        </header>
        
        <div class="metrics-grid">
            <div class="metric-card info">
                <h3>Всего вызовов</h3>
                <div class="value">$TOTAL_CALLS</div>
            </div>
            <div class="metric-card success">
                <h3>Успешных</h3>
                <div class="value">$TOTAL_SUCCESS</div>
            </div>
            <div class="metric-card danger">
                <h3>Ошибок</h3>
                <div class="value">$TOTAL_FAILED</div>
            </div>
            <div class="metric-card">
                <h3>Успешность</h3>
                <div class="value">${SUCCESS_RATE}%</div>
                <div class="progress-bar">
                    <div class="progress-fill success" style="width: ${SUCCESS_RATE}%"></div>
                </div>
            </div>
            <div class="metric-card">
                <h3>Среднее время</h3>
                <div class="value">${AVG_TIME}с</div>
            </div>
            <div class="metric-card">
                <h3>Пик нагрузки</h3>
                <div class="value">${PEAK_HOUR}:00</div>
            </div>
        </div>
        
        <div class="section">
            <h2>📊 Статистика по агентам</h2>
            <table>
                <thead>
                    <tr>
                        <th>Агент</th>
                        <th>Вызовы</th>
                        <th>Успех</th>
                        <th>Ошибки</th>
                        <th>Успешность</th>
                        <th>Время (с)</th>
                        <th>Токены</th>
                    </tr>
                </thead>
                <tbody>
HMLEOF

    # Добавление строк агентов
    echo "$AGENTS_JSON" | jq -r 'to_entries | sort_by(-.value.calls) | .[] | 
        "| \(.key) | \(.value.calls) | \(.value.success) | \(.value.failed) | \(.value.success_rate)% | \(.value.total_time_seconds) | \(.value.total_tokens) |"' >> "$html_file"
    
    cat >> "$html_file" << HTMLEOF
                </tbody>
            </table>
        </div>
        
        <div class="section">
            <h2>🔥 Heatmap нагрузки по часам</h2>
            <div class="heatmap">
HTMLEOF

    # Добавление heatmap
    while IFS= read -r line; do
        if [ -n "$line" ]; then
            echo "                <div class=\"heatmap-item\">$line</div>" >> "$html_file"
        fi
    done <<< "$heatmap"
    
    cat >> "$html_file" << HTMLEOF
            </div>
            <p style="margin-top: 15px; font-size: 0.9em;">
                🔴 Высокая (≥10) | 🟠 Средняя (5-9) | 🟡 Низкая (2-4) | 🟢 Очень низкая (1) | ⚪ Нет вызовов
            </p>
        </div>
        
        <div class="section">
            <h2>⚠️ Аномалии</h2>
HTMLEOF

    # Добавление аномалий
    local anomaly_count=$(echo "$ANOMALIES_JSON" | jq 'length')
    if [ "$anomaly_count" -gt 0 ]; then
        echo "$ANOMALIES_JSON" | jq -r '.[] | 
            "<div class=\"anomaly-item\"><strong>⚠️ \(.agent)</strong>: \(.description)</div>"' >> "$html_file"
    else
        echo "            <p>✅ Аномалий не обнаружено</p>" >> "$html_file"
    fi
    
    cat >> "$html_file" << HTMLEOF
        </div>
        
        <div class="section">
            <h2>🎯 Топ проблемных агентов</h2>
            <pre style="background: var(--bg-card); padding: 15px; border-radius: 5px; overflow-x: auto;">$problematic</pre>
        </div>
        
        <div class="section">
            <h2>💡 Рекомендации</h2>
            <div style="background: var(--bg-card); padding: 15px; border-radius: 5px;">
HTMLEOF

    # Добавление рекомендаций (конвертация markdown в простой HTML)
    echo "$recommendations" | sed 's/##/<h3>/g; s/$/<\/h3>/g; s/^\*\*/<strong>/g; s/\*\*$/<\/strong>/g; s/^\*/<li>/g; s/$/<\/li>/g' >> "$html_file"
    
    cat >> "$html_file" << HTMLEOF
            </div>
        </div>
        
        <footer>
            <p>Qwen Orchestrator Kit - Agent Analytics Dashboard v1.0.0</p>
            <p>Сгенерировано: $TIMESTAMP</p>
        </footer>
    </div>
</body>
</html>
HTMLEOF
    
    log_success "HTML дашборд: $html_file"
    echo "$html_file"
}

# Генерация Markdown дашборда
generate_markdown_dashboard() {
    log_step "Генерация Markdown дашборда..."
    
    local md_file="$OUTPUT_DIR/agent-dashboard-$TIMESTAMP.md"
    local heatmap=$(generate_heatmap)
    local problematic=$(generate_top_problematic)
    local recommendations=$(generate_recommendations)
    
    # Определение статуса
    local status_emoji="✅"
    local status_text="Здорова"
    if [ "$SUCCESS_RATE" -lt 70 ]; then
        status_emoji="🚨"
        status_text="Критично"
    elif [ "$SUCCESS_RATE" -lt 90 ]; then
        status_emoji="⚠️"
        status_text="Внимание"
    fi
    
    cat > "$md_file" << EOF
# 🤖 Agent Analytics Dashboard

**Дата**: $DATE  
**Время генерации**: $TIMESTAMP  
**Статус**: $status_emoji $status_text

---

## 📈 Ключевые метрики

| Метрика | Значение |
|---------|----------|
| Всего вызовов | $TOTAL_CALLS |
| Успешных | $TOTAL_SUCCESS |
| Ошибок | $TOTAL_FAILED |
| Успешность | ${SUCCESS_RATE}% |
| Среднее время | ${AVG_TIME}с |
| Общее время | ${TOTAL_TIME}с ($(($TOTAL_TIME / 60)) мин) |
| Всего токенов | $TOTAL_TOKENS |
| Пик нагрузки | ${PEAK_HOUR}:00 |

---

## 📊 Статистика по агентам

| Агент | Вызовы | Успех | Ошибки | Успешность | Время (с) | Токены |
|-------|--------|-------|--------|------------|-----------|--------|
EOF

    # Добавление строк агентов
    echo "$AGENTS_JSON" | jq -r 'to_entries | sort_by(-.value.calls) | .[] | 
        "| \(.key) | \(.value.calls) | \(.value.success) | \(.value.failed) | \(.value.success_rate)% | \(.value.total_time_seconds) | \(.value.total_tokens) |"' >> "$md_file"
    
    cat >> "$md_file" << EOF

---

## 🔥 Heatmap нагрузки по часам

\`\`\`
$heatmap
\`\`\`

**Легенда**: 🔴 Высокая (≥10) | 🟠 Средняя (5-9) | 🟡 Низкая (2-4) | 🟢 Очень низкая (1) | ⚪ Нет вызовов

---

## ⚠️ Аномалии

EOF

    # Добавление аномалий
    local anomaly_count=$(echo "$ANOMALIES_JSON" | jq 'length')
    if [ "$anomaly_count" -gt 0 ]; then
        echo "$ANOMALIES_JSON" | jq -r '.[] | "- ⚠️ **\(.agent)**: \(.description)"' >> "$md_file"
    else
        echo "✅ Аномалий не обнаружено" >> "$md_file"
    fi
    
    cat >> "$md_file" << EOF

---

## 🎯 Топ проблемных агентов

$problematic

---

## 💡 Рекомендации

$recommendations

---

*Dashboard сгенерирован Qwen Orchestrator Kit - Agent Analytics v1.0.0*
EOF
    
    log_success "Markdown дашборд: $md_file"
    echo "$md_file"
}

# Вывод краткой сводки
print_summary() {
    echo ""
    log_header "Agent Dashboard Summary"
    echo ""
    
    echo -e "${WHITE}Ключевые метрики:${NC}"
    echo "  - Всего вызовов: $TOTAL_CALLS"
    echo "  - Успешность: ${SUCCESS_RATE}%"
    echo "  - Среднее время: ${AVG_TIME}с"
    echo "  - Пик нагрузки: ${PEAK_HOUR}:00"
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
            -f|--format)
                OUTPUT_FORMAT="$2"
                shift 2
                ;;
            -l|--log)
                LOG_FILE="$2"
                shift 2
                ;;
            -a|--analysis)
                ANALYSIS_FILE="$2"
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
        log_header "Generate Agent Dashboard v1.0.0"
        echo ""
    fi
    
    # Проверки
    if ! check_dependencies; then
        exit 1
    fi
    
    # Запуск анализатора если нужно
    if ! run_analyzer_if_needed; then
        exit 1
    fi
    
    # Чтение данных
    read_analysis_data
    
    # Генерация дашбордов
    case "$OUTPUT_FORMAT" in
        html)
            generate_html_dashboard > /dev/null
            ;;
        md)
            generate_markdown_dashboard > /dev/null
            ;;
        both)
            generate_html_dashboard > /dev/null
            generate_markdown_dashboard > /dev/null
            ;;
    esac
    
    # Вывод
    if [ "$QUIET" = false ]; then
        print_summary
        log_success "Дашборд сгенерирован"
        echo ""
        echo -e "${WHITE}Файлы:${NC}"
        if [ "$OUTPUT_FORMAT" = "html" ] || [ "$OUTPUT_FORMAT" = "both" ]; then
            echo "  - HTML: $OUTPUT_DIR/agent-dashboard-$TIMESTAMP.html"
        fi
        if [ "$OUTPUT_FORMAT" = "md" ] || [ "$OUTPUT_FORMAT" = "both" ]; then
            echo "  - Markdown: $OUTPUT_DIR/agent-dashboard-$TIMESTAMP.md"
        fi
        echo ""
    fi
    
    exit 0
}

main "$@"
