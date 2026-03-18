#!/bin/bash
# Скрипт: .qwen/scripts/quality-gates/check-specifications.sh
# Назначение: Проверка качества спецификаций (Gate 5: Pre-Implementation Gate)
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

log_info "=== Gate 5: Pre-Implementation Gate ==="
log_info "Спецификация: $SPEC_DIR"

ERRORS=0
WARNINGS=0

# Проверка 1: Наличие spec.md
log_info "Проверка 1: Файл спецификации..."
SPEC_FILE="$SPEC_DIR/spec.md"

if [ ! -f "$SPEC_FILE" ]; then
    log_error "spec.md отсутствует"
    ERRORS=$((ERRORS + 1))
else
    log_success "spec.md найден"
    
    # Проверка наличия обязательных разделов
    log_info "Проверка разделов спецификации..."
    
    SECTIONS=(
        "Краткое описание"
        "Контекст"
        "Акторы"
        "Требования"
        "Сценарии использования"
        "Условия успеха"
        "Ограничения"
        "Предположения"
    )
    
    for section in "${SECTIONS[@]}"; do
        if ! grep -q "## $section" "$SPEC_FILE" 2>/dev/null; then
            log_warning "Отсутствует раздел: $section"
            WARNINGS=$((WARNINGS + 1))
        fi
    done
fi

# Проверка 2: Тестируемость требований
log_info "Проверка 2: Тестируемость требований..."

if [ -f "$SPEC_FILE" ]; then
    # Проверка на наличие расплывчатых формулировок
    if grep -qi "должен быть быстрый\|должен быть удобный\|должен быть красивый" "$SPEC_FILE" 2>/dev/null; then
        log_warning "Найдены расплывчатые формулировки (быстрый, удобный, красивый)"
        WARNINGS=$((WARNINGS + 1))
    fi
    
    # Проверка на наличие измеримых критериев
    if ! grep -qi "менее.*секунд\|более.*раз\|9[0-9]%\|100%" "$SPEC_FILE" 2>/dev/null; then
        log_warning "Отсутствуют измеримые критерии производительности"
        WARNINGS=$((WARNINGS + 1))
    fi
fi

# Проверка 3: Отсутствие деталей реализации
log_info "Проверка 3: Отсутствие деталей реализации..."

if [ -f "$SPEC_FILE" ]; then
    # Проверка на наличие названий фреймворков
    if grep -qi "react\|angular\|vue\|django\|flask\|express" "$SPEC_FILE" 2>/dev/null; then
        log_warning "Найдены названия фреймворков (должно быть только в plan.md)"
        WARNINGS=$((WARNINGS + 1))
    fi
    
    # Проверка на наличие названий баз данных
    if grep -qi "postgresql\|mysql\|mongodb\|redis" "$SPEC_FILE" 2>/dev/null; then
        log_warning "Найдены названия БД (должно быть только в plan.md)"
        WARNINGS=$((WARNINGS + 1))
    fi
fi

# Проверка 4: Наличие plan.md
log_info "Проверка 4: Файл плана реализации..."
PLAN_FILE="$SPEC_DIR/plan.md"

if [ ! -f "$PLAN_FILE" ]; then
    log_error "plan.md отсутствует"
    ERRORS=$((ERRORS + 1))
else
    log_success "plan.md найден"
fi

# Проверка 5: Наличие tasks.md
log_info "Проверка 5: Файл задач..."
TASKS_FILE="$SPEC_DIR/tasks.md"

if [ ! -f "$TASKS_FILE" ]; then
    log_error "tasks.md отсутствует"
    ERRORS=$((ERRORS + 1))
else
    log_success "tasks.md найден"
    
    # Проверка наличия назначений агентов
    AGENT_ASSIGNMENTS=$(grep -c "\[agent:" "$TASKS_FILE" 2>/dev/null || echo 0)
    if [ "$AGENT_ASSIGNMENTS" -eq 0 ]; then
        log_warning "Назначения агентов в задачах отсутствуют"
        WARNINGS=$((WARNINGS + 1))
    else
        log_success "Найдено назначений агентов: $AGENT_ASSIGNMENTS"
    fi
fi

# Проверка 6: Наличие Phase 0
log_info "Проверка 6: Результаты Фазы 0..."
PHASE0_PLAN="$SPEC_DIR/plans/phase0-plan.json"
PHASE0_AGENTS="$SPEC_DIR/plans/phase0-agents.json"
PHASE0_ASSIGNMENTS="$SPEC_DIR/plans/phase0-assignments.json"

if [ ! -f "$PHASE0_PLAN" ]; then
    log_error "phase0-plan.json отсутствует"
    ERRORS=$((ERRORS + 1))
else
    log_success "phase0-plan.json найден"
fi

if [ ! -f "$PHASE0_AGENTS" ]; then
    log_warning "phase0-agents.json отсутствует"
    WARNINGS=$((WARNINGS + 1))
else
    log_success "phase0-agents.json найден"
fi

if [ ! -f "$PHASE0_ASSIGNMENTS" ]; then
    log_warning "phase0-assignments.json отсутствует"
    WARNINGS=$((WARNINGS + 1))
else
    log_success "phase0-assignments.json найден"
fi

# Проверка 7: Пользовательские сценарии
log_info "Проверка 7: Пользовательские сценарии..."

if [ -f "$SPEC_FILE" ]; then
    if ! grep -q "Сценарии использования\|User Stories\|Use Cases" "$SPEC_FILE" 2>/dev/null; then
        log_warning "Пользовательские сценарии не определены"
        WARNINGS=$((WARNINGS + 1))
    else
        log_success "Пользовательские сценарии определены"
    fi
fi

# Проверка 8: Риски и допущения
log_info "Проверка 8: Риски и допущения..."

if [ -f "$SPEC_FILE" ]; then
    if ! grep -q "Риски\|Предположения" "$SPEC_FILE" 2>/dev/null; then
        log_warning "Риски и допущения не идентифицированы"
        WARNINGS=$((WARNINGS + 1))
    else
        log_success "Риски и допущения определены"
    fi
fi

# Финальный отчет
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_info "Результаты проверки:"
echo "  ✅ Успешно: $((8 - ERRORS - WARNINGS))"
echo "  ⚠️  Предупреждения: $WARNINGS"
echo "  ❌ Ошибки: $ERRORS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ $ERRORS -gt 0 ]; then
    echo ""
    log_error "Gate 5 не пройден ($ERRORS ошибок)"
    echo ""
    log_info "Необходимо устранить ошибки перед продолжением:"
    
    if [ ! -f "$SPEC_FILE" ]; then
        echo "  1. Создайте spec.md через: speckit.specify"
    fi
    
    if [ ! -f "$PLAN_FILE" ]; then
        echo "  2. Создайте plan.md через: speckit.plan"
    fi
    
    if [ ! -f "$TASKS_FILE" ]; then
        echo "  3. Создайте tasks.md через: speckit.tasks"
    fi
    
    if [ ! -f "$PHASE0_PLAN" ]; then
        echo "  4. Инициализируйте Фазу 0: .qwen/specify/scripts/phase0-analyzer.sh $SPEC_DIR"
    fi
    
    echo ""
    exit 1
fi

if [ $WARNINGS -gt 0 ]; then
    echo ""
    log_warning "Gate 5 пройден с предупреждениями ($WARNINGS)"
    log_info "Рекомендуется устранить предупреждения перед продолжением"
    echo ""
    log_info "Продолжить реализацию? (да/нет)"
    read -r RESPONSE
    if [[ ! $RESPONSE =~ ^(да|yes|y)$ ]]; then
        log_error "Реализация отменена пользователем"
        exit 1
    fi
else
    echo ""
    log_success "Gate 5: Pre-Implementation Gate ПРОЙДЕН ✅"
    echo ""
    log_info "Следующий шаг: speckit.implement"
    echo ""
fi

exit 0
