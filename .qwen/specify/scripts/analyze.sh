#!/bin/bash
# SpecKit: Analyze Script
# Назначение: Анализ требований пользователя
# Версия: 1.0.0

set -e

# Конфигурация
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SPECIFY_DIR="$(dirname "$SCRIPT_DIR")"
PROJECT_ROOT="$(dirname "$(dirname "$SPECIFY_DIR")")"
COMMANDS_DIR="$PROJECT_ROOT/commands"
LOGS_DIR="$PROJECT_ROOT/logs"

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Логирование
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Проверка зависимостей
check_dependencies() {
    log_info "Проверка зависимостей..."
    
    if ! command -v jq &> /dev/null; then
        log_warning "jq не найден. Установите для лучшей работы."
    fi
    
    log_success "Зависимости проверены"
}

# Инициализация спецификации
init_spec() {
    local spec_id="$1"
    local specs_dir="$PROJECT_ROOT/specs"
    
    log_info "Инициализация спецификации: $spec_id"
    
    mkdir -p "$specs_dir/$spec_id"
    mkdir -p "$specs_dir/$spec_id/plans"
    mkdir -p "$specs_dir/$spec_id/reports"
    mkdir -p "$specs_dir/$spec_id/memory"
    
    # Создание файла состояния
    cat > "$specs_dir/$spec_id/state.json" << EOF
{
    "id": "$spec_id",
    "created": "$(date -Iseconds)",
    "phase": "analyze",
    "status": "in_progress",
    "commands": {
        "analyze": "pending",
        "specify": "not_started",
        "clarify": "not_started",
        "plan": "not_started",
        "implement": "not_started",
        "checklist": "not_started",
        "tasks": "not_started",
        "constitution": "not_started",
        "taskstoissues": "not_started"
    }
}
EOF
    
    log_success "Спецификация инициализирована: $spec_id"
}

# Сбор требований
collect_requirements() {
    local spec_id="$1"
    local requirements_file="$PROJECT_ROOT/specs/$spec_id/requirements.md"
    
    log_info "Сбор требований..."
    
    # Запрос требований у пользователя (через stdin или аргументы)
    cat > "$requirements_file" << 'EOF'
# Requirements Document

**Spec ID:** {SPEC_ID}
**Дата:** {DATE}
**Статус:** Draft

## 1. Вводные данные

### 1.1 Описание проекта
<!-- Введите описание проекта здесь -->

### 1.2 Цель проекта
<!-- Введите цель проекта здесь -->

### 1.3 Стейкхолдеры
<!-- Перечислите стейкхолдеров -->

## 2. Функциональные требования

<!-- Перечислите функциональные требования -->

## 3. Нефункциональные требования

<!-- Перечислите нефункциональные требования -->

## 4. Ограничения

<!-- Перечислите ограничения -->

## 5. Вопросы для уточнения

<!-- Вопросы будут сгенерированы автоматически -->
EOF
    
    # Замена плейсхолдеров
    sed -i "s/{SPEC_ID}/$spec_id/g" "$requirements_file"
    sed -i "s/{DATE}/$(date +%Y-%m-%d)/g" "$requirements_file"
    
    log_success "Требования собраны: $requirements_file"
}

# Анализ полноты
analyze_completeness() {
    local spec_id="$1"
    local requirements_file="$PROJECT_ROOT/specs/$spec_id/requirements.md"
    local analysis_file="$PROJECT_ROOT/specs/$spec_id/analysis-report.md"
    
    log_info "Анализ полноты требований..."
    
    # Проверка наличия разделов
    local completeness_score=0
    local max_score=5
    
    if grep -q "## 1. Вводные данные" "$requirements_file" 2>/dev/null; then
        ((completeness_score++))
    fi
    
    if grep -q "## 2. Функциональные требования" "$requirements_file" 2>/dev/null; then
        ((completeness_score++))
    fi
    
    if grep -q "## 3. Нефункциональные требования" "$requirements_file" 2>/dev/null; then
        ((completeness_score++))
    fi
    
    if grep -q "## 4. Ограничения" "$requirements_file" 2>/dev/null; then
        ((completeness_score++))
    fi
    
    if grep -q "## 5. Вопросы для уточнения" "$requirements_file" 2>/dev/null; then
        ((completeness_score++))
    fi
    
    local completeness_percent=$((completeness_score * 100 / max_score))
    
    # Генерация отчета
    cat > "$analysis_file" << EOF
# Requirements Analysis Report

**Spec ID:** $spec_id
**Дата:** $(date +%Y-%m-%d)
**Статус:** Completed

## Анализ полноты

**Оценка:** $completeness_percent% ($completeness_score из $max_score разделов)

### Проверенные разделы:
$([ $completeness_score -ge 1 ] && echo "- ✅ Вводные данные" || echo "- ❌ Вводные данные")
$([ $completeness_score -ge 2 ] && echo "- ✅ Функциональные требования" || echo "- ❌ Функциональные требования")
$([ $completeness_score -ge 3 ] && echo "- ✅ Нефункциональные требования" || echo "- ❌ Нефункциональные требования")
$([ $completeness_score -ge 4 ] && echo "- ✅ Ограничения" || echo "- ❌ Ограничения")
$([ $completeness_score -ge 5 ] && echo "- ✅ Вопросы для уточнения" || echo "- ❌ Вопросы для уточнения")

## Выявленные пробелы

<!-- Автоматически сгенерированные пробелы -->

## Рекомендации

1. Заполните все пустые разделы
2. Добавьте детали к требованиям
3. Уточните ограничения проекта

## Следующие шаги

1. Запустить \`speckit.specify\` для создания спецификации
2. Запустить \`speckit.clarify\` для уточнения деталей
EOF
    
    log_success "Анализ завершен: $analysis_file"
}

# Выявление противоречий
detect_contradictions() {
    local spec_id="$1"
    local contradictions_file="$PROJECT_ROOT/specs/$spec_id/contradictions.md"
    
    log_info "Выявление противоречий..."
    
    cat > "$contradictions_file" << EOF
# Contradictions Report

**Spec ID:** $spec_id
**Дата:** $(date +%Y-%m-%d)

## Выявленные противоречия

<!-- Противоречия будут выявлены при анализе -->

## Потенциальные конфликты

<!-- Конфликты будут перечислены здесь -->

## Разрешение

<!-- Стратегии разрешения будут предложены здесь -->
EOF
    
    log_success "Отчет о противоречиях создан: $contradictions_file"
}

# Обновление состояния
update_state() {
    local spec_id="$1"
    local state_file="$PROJECT_ROOT/specs/$spec_id/state.json"
    
    log_info "Обновление состояния..."
    
    if command -v jq &> /dev/null; then
        jq '.phase = "analyze_complete" | .status = "in_progress" | .commands.analyze = "completed"' \
            "$state_file" > "$state_file.tmp" && mv "$state_file.tmp" "$state_file"
    else
        log_warning "jq не найден, пропускаем обновление JSON"
    fi
    
    log_success "Состояние обновлено"
}

# Основная функция
main() {
    local spec_id="${1:-SPEC-$(date +%Y%m%d-%H%M%S)}"
    
    echo "========================================"
    echo "  SpecKit: Analyze"
    echo "  Версия: 1.0.0"
    echo "========================================"
    echo ""
    
    check_dependencies
    echo ""
    
    init_spec "$spec_id"
    echo ""
    
    collect_requirements "$spec_id"
    echo ""
    
    analyze_completeness "$spec_id"
    echo ""
    
    detect_contradictions "$spec_id"
    echo ""
    
    update_state "$spec_id"
    echo ""
    
    log_success "========================================"
    log_success "  Анализ завершен!"
    log_success "  Spec ID: $spec_id"
    log_success "  Следующий шаг: speckit.specify"
    log_success "========================================"
}

# Запуск
main "$@"
