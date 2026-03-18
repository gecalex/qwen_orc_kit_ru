#!/bin/bash
# Скрипт: .qwen/scripts/quality-gates/check-planning.sh
# Назначение: Проверка качества планирования (Gate 1)
# Блокирующая: true (останавливает процесс при неудаче)

set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Проверка аргументов
SPEC_DIR="$1"

if [ -z "$SPEC_DIR" ]; then
    log_error "Использование: $0 <путь-к-спецификации>"
    log_info "Пример: $0 .qwen/specify/specs/001-user-auth"
    exit 1
fi

log_info "=== Gate 1: Проверка планирования ==="
log_info "Спецификация: $SPEC_DIR"

ERRORS=0
WARNINGS=0

# Проверка 1: Наличие плана Фазы 0
log_info "Проверка 1: План Фазы 0..."
PLAN_FILE="$SPEC_DIR/plans/phase0-plan.json"

if [ ! -f "$PLAN_FILE" ]; then
    log_error "План Фазы 0 отсутствует: $PLAN_FILE"
    ERRORS=$((ERRORS + 1))
else
    log_success "План Фазы 0 найден"
    
    # Проверка содержимого плана
    if grep -q '"phase": 0' "$PLAN_FILE"; then
        log_success "Фаза указана корректно"
    else
        log_error "Некорректный номер фазы в плане"
        ERRORS=$((ERRORS + 1))
    fi
    
    if grep -q '"status":' "$PLAN_FILE"; then
        log_success "Статус плана указан"
    else
        log_warning "Статус плана отсутствует"
        WARNINGS=$((WARNINGS + 1))
    fi
fi

# Проверка 2: Наличие assignments
log_info "Проверка 2: Назначения агентов..."
ASSIGNMENTS_FILE="$SPEC_DIR/plans/phase0-assignments.json"

if [ ! -f "$ASSIGNMENTS_FILE" ]; then
    log_error "Назначения агентов отсутствуют: $ASSIGNMENTS_FILE"
    ERRORS=$((ERRORS + 1))
else
    log_success "Назначения агентов найдены"
fi

# Проверка 3: Наличие phase0-agents.json
log_info "Проверка 3: Анализ агентов..."
AGENTS_FILE="$SPEC_DIR/plans/phase0-agents.json"

if [ ! -f "$AGENTS_FILE" ]; then
    log_error "Анализ агентов отсутствует: $AGENTS_FILE"
    ERRORS=$((ERRORS + 1))
else
    log_success "Анализ агентов найден"
    
    # Проверка наличия requiredAgents
    if grep -q '"requiredAgents":' "$AGENTS_FILE"; then
        log_success "Требуемые агенты определены"
    else
        log_warning "Требуемые агенты не определены"
        WARNINGS=$((WARNINGS + 1))
    fi
fi

# Проверка 4: Наличие tasks.md
log_info "Проверка 4: Файл задач..."
TASKS_FILE="$SPEC_DIR/tasks.md"

if [ ! -f "$TASKS_FILE" ]; then
    log_error "tasks.md отсутствует"
    ERRORS=$((ERRORS + 1))
else
    log_success "tasks.md найден"
    
    # Проверка наличия задач
    TASK_COUNT=$(grep -c "^\- \[" "$TASKS_FILE" 2>/dev/null || echo 0)
    if [ "$TASK_COUNT" -gt 0 ]; then
        log_success "Найдено задач: $TASK_COUNT"
    else
        log_warning "tasks.md пуст или не содержит задач"
        WARNINGS=$((WARNINGS + 1))
    fi
    
    # Проверка наличия назначений агентов в задачах
    AGENT_ASSIGNMENTS=$(grep -c "\[agent:" "$TASKS_FILE" 2>/dev/null || echo 0)
    if [ "$AGENT_ASSIGNMENTS" -gt 0 ]; then
        log_success "Найдено назначений агентов: $AGENT_ASSIGNMENTS"
    else
        log_warning "Назначения агентов в задачах отсутствуют"
        WARNINGS=$((WARNINGS + 1))
    fi
fi

# Проверка 5: Наличие plan.md
log_info "Проверка 5: Файл плана реализации..."
PLAN_MD_FILE="$SPEC_DIR/plan.md"

if [ ! -f "$PLAN_MD_FILE" ]; then
    log_error "plan.md отсутствует"
    ERRORS=$((ERRORS + 1))
else
    log_success "plan.md найден"
fi

# Проверка 6: Наличие spec.md
log_info "Проверка 6: Файл спецификации..."
SPEC_FILE="$SPEC_DIR/spec.md"

if [ ! -f "$SPEC_FILE" ]; then
    log_error "spec.md отсутствует"
    ERRORS=$((ERRORS + 1))
else
    log_success "spec.md найден"
fi

# Финальный отчет
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_info "Результаты проверки:"
echo "  ✅ Успешно: $((6 - ERRORS - WARNINGS))"
echo "  ⚠️  Предупреждения: $WARNINGS"
echo "  ❌ Ошибки: $ERRORS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ $ERRORS -gt 0 ]; then
    echo ""
    log_error "Gate 1 не пройден ($ERRORS ошибок)"
    echo ""
    log_info "Необходимо устранить ошибки перед продолжением:"
    
    if [ ! -f "$PLAN_FILE" ]; then
        echo "  1. Запустите: .qwen/specify/scripts/phase0-analyzer.sh $SPEC_DIR"
    fi
    
    if [ ! -f "$ASSIGNMENTS_FILE" ]; then
        echo "  2. Запустите: orc_planning_task_analyzer"
    fi
    
    if [ ! -f "$TASKS_FILE" ]; then
        echo "  3. Запустите: speckit.tasks"
    fi
    
    echo ""
    exit 1
fi

if [ $WARNINGS -gt 0 ]; then
    echo ""
    log_warning "Gate 1 пройден с предупреждениями ($WARNINGS)"
    log_info "Рекомендуется устранить предупреждения перед продолжением"
    echo ""
else
    echo ""
    log_success "Gate 1: Planning Quality Gate ПРОЙДЕН ✅"
    echo ""
    log_info "Следующий шаг: speckit.implement"
    echo ""
fi

exit 0
