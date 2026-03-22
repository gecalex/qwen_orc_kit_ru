#!/bin/bash
# SpecKit: Implement Script
# Назначение: Реализация проекта по плану
# Версия: 1.0.0

set -e

# Конфигурация
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SPECIFY_DIR="$(dirname "$SCRIPT_DIR")"
PROJECT_ROOT="$(dirname "$(dirname "$SPECIFY_DIR")")"
LOGS_DIR="$PROJECT_ROOT/logs"
AGENTS_DIR="$PROJECT_ROOT/.qwen/agents"

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Логирование
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_progress() { echo -e "${CYAN}[PROGRESS]${NC} $1"; }

# Проверка зависимостей
check_dependencies() {
    log_info "Проверка зависимостей..."
    
    if [ ! -f "$PROJECT_ROOT/specs/$SPEC_ID/plan.md" ]; then
        log_error "plan.md не найден. Запустите сначала speckit.plan"
        exit 1
    fi
    
    log_success "Зависимости проверены"
}

# Инициализация логов реализации
init_implementation_log() {
    local log_file="$PROJECT_ROOT/specs/$SPEC_ID/implementation-log.md"
    
    log_info "Инициализация лога реализации..."
    
    cat > "$log_file" << EOF
# Implementation Log: $PROJECT_NAME

**Spec ID:** $SPEC_ID
**Дата начала:** $(date +%Y-%m-%d\ %H:%M:%S)
**Статус:** In Progress

---

## Сводка

| Метрика | Значение |
|---------|----------|
| Всего задач | 0 |
| Выполнено | 0 |
| В процессе | 0 |
| Ожидает | 0 |
| Прогресс | 0% |

---

## Лог выполнения

EOF
    
    log_success "Лог инициализирован: $log_file"
}

# Выполнение фазы
execute_phase() {
    local phase_num="$1"
    local phase_name="$2"
    local log_file="$PROJECT_ROOT/specs/$SPEC_ID/implementation-log.md"
    
    log_progress "Начало фазы $phase_num: $phase_name"
    
    # Создание отчета о фазе
    local phase_report="$PROJECT_ROOT/specs/$SPEC_ID/phase-reports/phase-$phase_num-report.md"
    mkdir -p "$(dirname "$phase_report")"
    
    cat > "$phase_report" << EOF
# Phase $phase_num Report: $phase_name

**Spec ID:** $SPEC_ID
**Дата:** $(date +%Y-%m-%d)
**Статус:** In Progress

## Задачи фазы

| Задача | Статус | Время | Агент |
|--------|--------|-------|-------|
| | Pending | - | - |

## Результаты

<!-- Будет заполнено по завершении -->

## Проблемы

<!-- Будет заполнено при возникновении -->

## Метрики

- Начато: $(date +%Y-%m-%d\ %H:%M:%S)
- Завершено: -
- Длительность: -
EOF
    
    # Обновление общего лога
    echo "" >> "$log_file"
    echo "### Фаза $phase_num: $phase_name - Начата $(date +%Y-%m-%d\ %H:%M:%S)" >> "$log_file"
    
    log_success "Фаза $phase_num инициализирована"
}

# Делегирование задачи агенту
delegate_task() {
    local task_id="$1"
    local task_desc="$2"
    local agent="$3"
    local log_file="$PROJECT_ROOT/specs/$SPEC_ID/implementation-log.md"
    
    log_info "Делегирование задачи $task_id агенту $agent..."
    
    # Создание директории для задачи
    local task_dir="$PROJECT_ROOT/specs/$SPEC_ID/tasks/$task_id"
    mkdir -p "$task_dir"
    
    # Создание контекста задачи
    cat > "$task_dir/context.md" << EOF
# Task Context: $task_id

**Описание:** $task_desc
**Агент:** $agent
**Дата делегирования:** $(date +%Y-%m-%d\ %H:%M:%S)

## Инструкции для агента

1. Изучите spec.md для понимания контекста
2. Проверьте plan.md для деталей задачи
3. Выполните задачу согласно требованиям
4. Создайте отчет о выполнении

## Требования

- Следуйте constitution.md
- Обновляйте tasks.md
- Создавайте тесты

## Ожидаемый результат

<!-- Описание ожидаемого результата -->

EOF
    
    # Логирование
    echo "- [$task_id] Делегировано $agent: $task_desc" >> "$log_file"
    
    log_success "Задача $task_id делегирована"
}

# Мониторинг прогресса
monitor_progress() {
    local log_file="$PROJECT_ROOT/specs/$SPEC_ID/implementation-log.md"
    local total_tasks=17  # Из плана
    local completed=0
    local in_progress=0
    
    log_info "Мониторинг прогресса..."
    
    # Подсчет выполненных задач
    if [ -d "$PROJECT_ROOT/specs/$SPEC_ID/tasks" ]; then
        for task_dir in "$PROJECT_ROOT/specs/$SPEC_ID/tasks"/T-*; do
            if [ -d "$task_dir" ]; then
                if [ -f "$task_dir/completed.md" ]; then
                    ((completed++))
                elif [ -f "$task_dir/in_progress.md" ]; then
                    ((in_progress++))
                fi
            fi
        done
    fi
    
    local pending=$((total_tasks - completed - in_progress))
    local progress=$((completed * 100 / total_tasks))
    
    # Обновление сводки в логе
    local temp_file=$(mktemp)
    sed "s/| Всего задач | [0-9]* |/| Всего задач | $total_tasks |/" "$log_file" | \
    sed "s/| Выполнено | [0-9]* |/| Выполнено | $completed |/" | \
    sed "s/| В процессе | [0-9]* |/| В процессе | $in_progress |/" | \
    sed "s/| Ожидает | [0-9]* |/| Ожидает | $pending |/" | \
    sed "s/| Прогресс | [0-9]*% |/| Прогресс | ${progress}% |/" > "$temp_file"
    mv "$temp_file" "$log_file"
    
    log_progress "Прогресс: $completed/$total_tasks (${progress}%) - В процессе: $in_progress"
}

# Создание итогового резюме
create_summary() {
    local summary_file="$PROJECT_ROOT/specs/$SPEC_ID/implementation-summary.md"
    
    log_info "Создание итогового резюме..."
    
    cat > "$summary_file" << EOF
# Implementation Summary: $PROJECT_NAME

**Spec ID:** $SPEC_ID
**Дата завершения:** $(date +%Y-%m-%d)
**Статус:** Completed

---

## Итоговая сводка

| Метрика | Значение |
|---------|----------|
| Всего задач | - |
| Выполнено | - |
| Не выполнено | - |
| Общий прогресс | -% |

---

## Выполненные фазы

| Фаза | Название | Статус | Длительность |
|------|----------|--------|--------------|
| 0 | Подготовка | - | - |
| 1 | Инфраструктура | - | - |
| 2 | Основные функции | - | - |
| 3 | Интеграции | - | - |
| 4 | Тестирование | - | - |
| 5 | Документирование | - | - |
| 6 | Релиз | - | - |

---

## Внесенные изменения

### Измененные файлы
- 

### Созданные файлы
- 

### Удаленные файлы
- 

---

## Метрики качества

- Покрытие тестами: -%
- Предупреждения линтера: 0
- Критические проблемы: 0

---

## Извлеченные уроки

<!-- Будет заполнено после завершения -->

---

## Следующие шаги

1. Запустить speckit.checklist для приемки
2. Обновить документацию
3. Подготовить релиз
EOF
    
    log_success "Резюме создано: $summary_file"
}

# Обновление состояния
update_state() {
    local state_file="$PROJECT_ROOT/specs/$SPEC_ID/state.json"
    
    log_info "Обновление состояния..."
    
    if command -v jq &> /dev/null && [ -f "$state_file" ]; then
        jq '.phase = "implement_complete" | .commands.implement = "completed"' \
            "$state_file" > "$state_file.tmp" && mv "$state_file.tmp" "$state_file"
    fi
    
    log_success "Состояние обновлено"
}

# Основная функция
main() {
    SPEC_ID="${1:-}"
    PROJECT_NAME="${2:-New Project}"
    PHASE="${3:-all}"
    
    if [ -z "$SPEC_ID" ]; then
        SPEC_ID=$(ls -t "$PROJECT_ROOT/specs/" 2>/dev/null | head -1)
        if [ -z "$SPEC_ID" ]; then
            log_error "SPEC_ID не указан и спецификации не найдены"
            exit 1
        fi
    fi
    
    echo "========================================"
    echo "  SpecKit: Implement"
    echo "  Версия: 1.0.0"
    echo "  Spec ID: $SPEC_ID"
    echo "========================================"
    echo ""
    
    check_dependencies
    echo ""
    
    init_implementation_log
    echo ""
    
    # Выполнение фаз
    if [ "$PHASE" = "all" ]; then
        execute_phase "0" "Подготовка"
        execute_phase "1" "Инфраструктура"
        execute_phase "2" "Основные функции"
        execute_phase "3" "Интеграции"
        execute_phase "4" "Тестирование"
        execute_phase "5" "Документирование"
        execute_phase "6" "Релиз"
    else
        case "$PHASE" in
            0) execute_phase "0" "Подготовка" ;;
            1) execute_phase "1" "Инфраструктура" ;;
            2) execute_phase "2" "Основные функции" ;;
            3) execute_phase "3" "Интеграции" ;;
            4) execute_phase "4" "Тестирование" ;;
            5) execute_phase "5" "Документирование" ;;
            6) execute_phase "6" "Релиз" ;;
            *) log_error "Неизвестная фаза: $PHASE"; exit 1 ;;
        esac
    fi
    
    echo ""
    
    monitor_progress
    echo ""
    
    create_summary
    echo ""
    
    update_state
    echo ""
    
    log_success "========================================"
    log_success "  Реализация инициирована!"
    log_success "  Файлы:"
    log_success "  - implementation-log.md"
    log_success "  - implementation-summary.md"
    log_success "  - phase-reports/"
    log_success "  Следующий шаг: speckit.checklist"
    log_success "========================================"
}

# Запуск
main "$@"
