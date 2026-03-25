#!/bin/bash
#
# Checklist Runner - Интерактивный запуск чек-листов
# Назначение: Пошаговое прохождение, отметка выполненных, сохранение прогресса
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
CHECKLISTS_DIR="$SCRIPT_DIR"
PROGRESS_DIR="$SCRIPT_DIR/.progress"
TIMESTAMP=$(date +%Y-%m-%d_%H-%M-%S)
DATE=$(date +%Y-%m-%d)

# Глобальные переменные
CURRENT_CHECKLIST=""
CURRENT_FILE=""
declare -a ITEMS=()
declare -a ITEM_STATUS=()
CURRENT_ITEM=0
TOTAL_ITEMS=0

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
${WHITE}Checklist Runner v1.0.0${NC}

Интерактивный запуск чек-листов

${WHITE}Использование:${NC}
  $(basename "$0") [OPTIONS] <checklist-name>

${WHITE}Опции:${NC}
  -h, --help              Показать эту справку
  -l, --list              Показать список доступных чек-листов
  -r, --resume            Возобновить последний сеанс
  -s, --status            Показать статус сохраненных прогрессов

${WHITE}Доступные чек-листы:${NC}
  - Pre-Flight
  - Pre-Commit
  - Pre-Merge
  - TDD
  - Agent Assignment
  - Specification
  - Phase 0
  - Initialization
  - Release
  - Health Check

${WHITE}Команды в интерактивном режиме:${NC}
  y, yes, ✅ - Выполнено
  n, no, ❌   - Не выполнено
  s, skip     - Пропустить
  q, quit     - Выйти с сохранением
  r, retry    - Повторить текущий
  h, help     - Помощь

${WHITE}Примеры:${NC}
  $(basename "$0") "Pre-Flight"             # Запуск чек-листа
  $(basename "$0") --list                   # Список чек-листов
  $(basename "$0") --resume                 # Возобновить сеанс

EOF
}

# Показать список чек-листов
show_checklist_list() {
    echo ""
    log_header "Доступные чек-листы"
    echo ""
    
    for file in "$CHECKLISTS_DIR"/*-checklist.md; do
        if [ -f "$file" ]; then
            local name=$(basename "$file" -checklist.md | sed 's/-/ /g' | sed 's/\b\(.\)/\u\1/g')
            local items=$(grep -c "\- \[" "$file" 2>/dev/null || echo "0")
            echo -e "  ${CYAN}•${NC} $name ($items пунктов)"
        fi
    done
    
    echo ""
}

# Показать статус сохраненных прогрессов
show_progress_status() {
    echo ""
    log_header "Сохраненные прогрессы"
    echo ""
    
    if [ ! -d "$PROGRESS_DIR" ] || [ -z "$(ls -A "$PROGRESS_DIR" 2>/dev/null)" ]; then
        echo "  Нет сохраненных прогрессов"
        echo ""
        return
    fi
    
    for file in "$PROGRESS_DIR"/*.progress; do
        if [ -f "$file" ]; then
            local name=$(basename "$file" .progress)
            local checklist=$(jq -r '.checklist' "$file" 2>/dev/null || echo "unknown")
            local current=$(jq -r '.current_item' "$file" 2>/dev/null || echo "0")
            local total=$(jq -r '.total_items' "$file" 2>/dev/null || echo "0")
            local timestamp=$(jq -r '.timestamp' "$file" 2>/dev/null || echo "unknown")
            
            echo -e "  ${CYAN}•${NC} $checklist"
            echo "      Прогресс: $current/$total"
            echo "      Сохранено: $timestamp"
            echo ""
        fi
    done
}

# Преобразование имени чек-листа в имя файла
checklist_name_to_file() {
    local name="$1"
    local file_name=$(echo "$name" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')
    echo "$CHECKLISTS_DIR/${file_name}-checklist.md"
}

# Парсинг чек-листа
parse_checklist() {
    local file="$1"
    
    if [ ! -f "$file" ]; then
        return 1
    fi
    
    ITEMS=()
    ITEM_STATUS=()
    
    while IFS= read -r line; do
        if [[ "$line" == *"- ["*"]"* ]]; then
            # Извлечение описания пункта
            local description=$(echo "$line" | sed 's/^- \[.\] //' | sed 's/.*\*\*[0-9.]*\*\*//' | xargs)
            ITEMS+=("$description")
            ITEM_STATUS+=("pending")
        fi
    done < "$file"
    
    TOTAL_ITEMS=${#ITEMS[@]}
}

# Сохранение прогресса
save_progress() {
    mkdir -p "$PROGRESS_DIR"
    
    local progress_file="$PROGRESS_DIR/${CURRENT_CHECKLIST}.progress"
    
    # Построение JSON статуса
    local status_json="["
    local first=true
    for ((i=0; i<TOTAL_ITEMS; i++)); do
        if [ "$first" = false ]; then
            status_json+=","
        fi
        first=false
        status_json+="\"${ITEM_STATUS[$i]}\""
    done
    status_json+="]"
    
    cat > "$progress_file" << EOF
{
  "checklist": "$CURRENT_CHECKLIST",
  "file": "$CURRENT_FILE",
  "current_item": $CURRENT_ITEM,
  "total_items": $TOTAL_ITEMS,
  "timestamp": "$TIMESTAMP",
  "status": $status_json
}
EOF
    
    log_info "Прогресс сохранен: $progress_file"
}

# Загрузка прогресса
load_progress() {
    local name="$1"
    local progress_file="$PROGRESS_DIR/${name}.progress"
    
    if [ ! -f "$progress_file" ]; then
        log_error "Прогресс не найден: $name"
        return 1
    fi
    
    CURRENT_CHECKLIST=$(jq -r '.checklist' "$progress_file")
    CURRENT_FILE=$(jq -r '.file' "$progress_file")
    CURRENT_ITEM=$(jq -r '.current_item' "$progress_file")
    TOTAL_ITEMS=$(jq -r '.total_items' "$progress_file")
    
    # Загрузка статусов
    local statuses=$(jq -r '.status[]' "$progress_file")
    ITEM_STATUS=()
    while IFS= read -r status; do
        ITEM_STATUS+=("$status")
    done <<< "$statuses"
    
    # Загрузка пунктов
    parse_checklist "$CURRENT_FILE"
    
    log_success "Прогресс загружен: $CURRENT_CHECKLIST (пункт $CURRENT_ITEM/$TOTAL_ITEMS)"
}

# Очистка прогресса
clear_progress() {
    local name="$1"
    local progress_file="$PROGRESS_DIR/${name}.progress"
    
    if [ -f "$progress_file" ]; then
        rm "$progress_file"
        log_info "Прогресс очищен: $name"
    fi
}

# Показать текущий пункт
show_current_item() {
    local item_num=$((CURRENT_ITEM + 1))
    local description="${ITEMS[$CURRENT_ITEM]}"
    local status="${ITEM_STATUS[$CURRENT_ITEM]}"
    
    echo ""
    echo -e "${WHITE}========================================${NC}"
    echo -e "${WHITE}  Пункт $item_num из $TOTAL_ITEMS${NC}"
    echo -e "${WHITE}========================================${NC}"
    echo ""
    echo -e "${CYAN}Задача:${NC} $description"
    echo ""
    
    case "$status" in
        pending)
            echo -e "  Статус: ${YELLOW}⏳ Ожидает проверки${NC}"
            ;;
        completed)
            echo -e "  Статус: ${GREEN}✅ Выполнено${NC}"
            ;;
        failed)
            echo -e "  Статус: ${RED}❌ Не выполнено${NC}"
            ;;
        skipped)
            echo -e "  Статус: ${BLUE}⏭️ Пропущено${NC}"
            ;;
    esac
    
    echo ""
    echo -e "${WHITE}Команды:${NC}"
    echo "  ${GREEN}y${NC}, ${GREEN}yes${NC}, ${GREEN}✅${NC}  - Выполнено"
    echo "  ${RED}n${NC}, ${RED}no${NC}, ${RED}❌${NC}   - Не выполнено"
    echo "  ${BLUE}s${NC}, ${BLUE}skip${NC}     - Пропустить"
    echo "  ${YELLOW}r${NC}, ${YELLOW}retry${NC}    - Повторить"
    echo "  ${MAGENTA}q${NC}, ${MAGENTA}quit${NC}     - Выйти с сохранением"
    echo "  ${CYAN}h${NC}, ${CYAN}help${NC}     - Помощь"
    echo ""
}

# Показать прогресс бар
show_progress_bar() {
    local completed=0
    local failed=0
    
    for status in "${ITEM_STATUS[@]}"; do
        case "$status" in
            completed) completed=$((completed + 1)) ;;
            failed) failed=$((failed + 1)) ;;
        esac
    done
    
    local percentage=0
    if [ "$TOTAL_ITEMS" -gt 0 ]; then
        percentage=$((completed * 100 / TOTAL_ITEMS))
    fi
    
    local bar_length=30
    local filled=$((percentage * bar_length / 100))
    local empty=$((bar_length - filled))
    
    local bar="["
    for ((i=0; i<filled; i++)); do bar+="█"; done
    for ((i=0; i<empty; i++)); do bar+="░"; done
    bar+="]"
    
    echo -ne "\r${WHITE}Прогресс:${NC} $bar ${percentage}% ($completed/$TOTAL_ITEMS)"
}

# Обработка ввода пользователя
handle_input() {
    local input=""
    read -r input
    
    input=$(echo "$input" | tr '[:upper:]' '[:lower:]' | xargs)
    
    case "$input" in
        y|yes|✅|"выполнено")
            ITEM_STATUS[$CURRENT_ITEM]="completed"
            CURRENT_ITEM=$((CURRENT_ITEM + 1))
            return 0
            ;;
        n|no|❌|"не выполнено"|"нет")
            ITEM_STATUS[$CURRENT_ITEM]="failed"
            CURRENT_ITEM=$((CURRENT_ITEM + 1))
            return 0
            ;;
        s|skip|"пропустить")
            ITEM_STATUS[$CURRENT_ITEM]="skipped"
            CURRENT_ITEM=$((CURRENT_ITEM + 1))
            return 0
            ;;
        r|retry|"повторить")
            # Остаемся на текущем пункте
            return 0
            ;;
        q|quit|"выйти"|"выход")
            save_progress
            echo ""
            log_info "Сеанс сохранен. Запустите с --resume для продолжения."
            exit 0
            ;;
        h|help|"помощь")
            show_current_item
            return 0
            ;;
        *)
            echo -e "${YELLOW}Неизвестная команда. Введите h для помощи.${NC}"
            return 0
            ;;
    esac
}

# Генерация отчета о завершении
generate_completion_report() {
    local completed=0
    local failed=0
    local skipped=0
    
    for status in "${ITEM_STATUS[@]}"; do
        case "$status" in
            completed) completed=$((completed + 1)) ;;
            failed) failed=$((failed + 1)) ;;
            skipped) skipped=$((skipped + 1)) ;;
        esac
    done
    
    local percentage=0
    if [ "$TOTAL_ITEMS" -gt 0 ]; then
        percentage=$((completed * 100 / TOTAL_ITEMS))
    fi
    
    echo ""
    log_header "Отчет о завершении"
    echo ""
    echo -e "${WHITE}Чек-лист:${NC} $CURRENT_CHECKLIST"
    echo -e "${WHITE}Дата:${NC} $DATE"
    echo ""
    echo -e "${WHITE}Результаты:${NC}"
    echo "  ✅ Выполнено: $completed"
    echo "  ❌ Не выполнено: $failed"
    echo "  ⏭️ Пропущено: $skipped"
    echo "  📊 Всего: $TOTAL_ITEMS"
    echo ""
    echo -e "${WHITE}Процент выполнения:${NC} ${percentage}%"
    echo ""
    
    # Определение статуса
    local status_emoji="❌"
    local status_text="Не выполнено"
    if [ "$percentage" -ge 90 ]; then
        status_emoji="✅"
        status_text="Отлично"
    elif [ "$percentage" -ge 70 ]; then
        status_emoji="⚠️"
        status_text="Хорошо"
    elif [ "$percentage" -ge 50 ]; then
        status_emoji="⚠️"
        status_text="Требует улучшения"
    fi
    
    echo -e "${WHITE}Статус:${NC} $status_emoji $status_text"
    echo ""
    
    # Список невыполненных пунктов
    if [ "$failed" -gt 0 ] || [ "$skipped" -gt 0 ]; then
        echo -e "${WHITE}Требуют внимания:${NC}"
        for ((i=0; i<TOTAL_ITEMS; i++)); do
            if [[ "${ITEM_STATUS[$i]}" == "failed" || "${ITEM_STATUS[$i]}" == "skipped" ]]; then
                local marker="❌"
                [[ "${ITEM_STATUS[$i]}" == "skipped" ]] && marker="⏭️"
                echo "  $marker ${ITEMS[$i]}"
            fi
        done
        echo ""
    fi
    
    # Сохранение отчета
    local report_file="$PROGRESS_DIR/${CURRENT_CHECKLIST}-report-$TIMESTAMP.md"
    
    cat > "$report_file" << EOF
# Checklist Completion Report

**Чек-лист**: $CURRENT_CHECKLIST  
**Дата**: $DATE  
**Время**: $TIMESTAMP

---

## Результаты

| Метрика | Значение |
|---------|----------|
| Выполнено | $completed |
| Не выполнено | $failed |
| Пропущено | $skipped |
| Всего | $TOTAL_ITEMS |
| Процент | ${percentage}% |

## Статус

$status_emoji $status_text

---

*Report сгенерирован Qwen Orchestrator Kit - Checklist Runner v1.0.0*
EOF
    
    log_success "Отчет сохранен: $report_file"
    
    # Очистка прогресса после завершения
    clear_progress "$CURRENT_CHECKLIST"
}

# Основной цикл
run_checklist() {
    local name="$1"
    local file=$(checklist_name_to_file "$name")
    
    if [ ! -f "$file" ]; then
        log_error "Чек-лист не найден: $name"
        return 1
    fi
    
    CURRENT_CHECKLIST="$name"
    CURRENT_FILE="$file"
    CURRENT_ITEM=0
    
    parse_checklist "$file"
    
    if [ "$TOTAL_ITEMS" -eq 0 ]; then
        log_error "Чек-лист не содержит пунктов"
        return 1
    fi
    
    echo ""
    log_header "Checklist Runner: $CURRENT_CHECKLIST"
    echo ""
    echo -e "${CYAN}Всего пунктов:${NC} $TOTAL_ITEMS"
    echo -e "${CYAN}Файл:${NC} $CURRENT_FILE"
    echo ""
    echo -e "${YELLOW}Нажмите Ctrl+C для выхода с сохранением${NC}"
    echo ""
    
    # Обработчик сигнала для сохранения при выходе
    trap 'echo ""; log_info "Сохранение прогресса..."; save_progress; exit 130' INT TERM
    
    # Основной цикл
    while [ "$CURRENT_ITEM" -lt "$TOTAL_ITEMS" ]; do
        show_progress_bar
        show_current_item
        handle_input
    done
    
    # Завершение
    generate_completion_report
    
    exit 0
}

# Основная функция
main() {
    local resume_mode=false
    local show_list=false
    local show_status=false
    local checklist_name=""
    
    # Парсинг аргументов
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -l|--list)
                show_list=true
                shift
                ;;
            -r|--resume)
                resume_mode=true
                shift
                ;;
            -s|--status)
                show_status=true
                shift
                ;;
            -*)
                log_error "Неизвестная опция: $1"
                show_help
                exit 1
                ;;
            *)
                checklist_name="$1"
                shift
                ;;
        esac
    done
    
    # Обработка режимов
    if [ "$show_list" = true ]; then
        show_checklist_list
        exit 0
    fi
    
    if [ "$show_status" = true ]; then
        show_progress_status
        exit 0
    fi
    
    if [ "$resume_mode" = true ]; then
        # Поиск последнего сохраненного прогресса
        if [ ! -d "$PROGRESS_DIR" ] || [ -z "$(ls -A "$PROGRESS_DIR"/*.progress 2>/dev/null)" ]; then
            log_error "Нет сохраненных прогрессов для возобновления"
            exit 1
        fi
        
        # Получение последнего файла
        local last_progress=$(ls -t "$PROGRESS_DIR"/*.progress 2>/dev/null | head -1)
        local name=$(basename "$last_progress" .progress)
        
        log_info "Возобновление: $name"
        load_progress "$name"
        run_checklist "$CURRENT_CHECKLIST"
        exit 0
    fi
    
    # Проверка имени чек-листа
    if [ -z "$checklist_name" ]; then
        log_error "Укажите имя чек-листа"
        show_help
        exit 1
    fi
    
    # Запуск чек-листа
    run_checklist "$checklist_name"
}

main "$@"
