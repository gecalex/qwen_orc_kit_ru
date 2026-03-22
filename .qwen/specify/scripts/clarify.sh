#!/bin/bash
# SpecKit: Clarify Script
# Назначение: Уточнение спецификации
# Версия: 1.0.0

set -e

# Конфигурация
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SPECIFY_DIR="$(dirname "$SCRIPT_DIR")"
PROJECT_ROOT="$(dirname "$(dirname "$SPECIFY_DIR")")"
LOGS_DIR="$PROJECT_ROOT/logs"

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Логирование
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Проверка зависимостей
check_dependencies() {
    log_info "Проверка зависимостей..."
    
    if [ ! -f "$PROJECT_ROOT/specs/$SPEC_ID/spec.md" ]; then
        log_error "spec.md не найден. Запустите сначала speckit.specify"
        exit 1
    fi
    
    log_success "Зависимости проверены"
}

# Анализ пробелов
analyze_gaps() {
    local spec_file="$PROJECT_ROOT/specs/$SPEC_ID/spec.md"
    local gaps_file="$PROJECT_ROOT/specs/$SPEC_ID/gaps-analysis.md"
    
    log_info "Анализ пробелов в спецификации..."
    
    local gaps_count=0
    local sections_checked=0
    
    # Проверка заполненности разделов
    while IFS= read -r line; do
        if [[ "$line" =~ ^##\ [0-9]+\.[0-9]+ ]]; then
            ((sections_checked++))
            # Проверка наличия контента после заголовка
            section_name=$(echo "$line" | sed 's/^## [0-9.]* //')
            
            # Простая эвристика: если после заголовка только комментарий
            if grep -A 3 "$line" "$spec_file" | grep -q "<!--"; then
                ((gaps_count++))
                echo "- Раздел $section_name: требует заполнения" >> "$gaps_file"
            fi
        fi
    done < "$spec_file"
    
    cat > "$gaps_file" << EOF
# Gaps Analysis Report

**Spec ID:** $SPEC_ID
**Дата:** $(date +%Y-%m-%d)

## Выявленные пробелы

**Всего проверено разделов:** $sections_checked
**Требуют заполнения:** $gaps_count

EOF
    
    log_success "Анализ пробелов завершен: $gaps_file"
}

# Генерация вопросов
generate_questions() {
    local questions_file="$PROJECT_ROOT/specs/$SPEC_ID/clarification-questions.md"
    
    log_info "Генерация вопросов для уточнения..."
    
    cat > "$questions_file" << EOF
# Clarification Questions

**Spec ID:** $SPEC_ID
**Дата:** $(date +%Y-%m-%d)
**Приоритет:** Высокий → Низкий

---

## Раздел 1: Обзор проекта

### Q1.1: Цель проекта
**Вопрос:** Какова основная цель этого проекта?
**Контекст:** Необходимо четкое понимание бизнес-цели
**Приоритет:** 🔴 Высокий

### Q1.2: Целевая аудитория
**Вопрос:** Кто является целевыми пользователями?
**Контекст:** Влияет на дизайн и функциональность
**Приоритет:** 🔴 Высокий

---

## Раздел 2: Функциональные требования

### Q2.1: Приоритизация функций
**Вопрос:** Какие функции являются обязательными (MVP)?
**Контекст:** Необходимо для планирования фаз
**Приоритет:** 🔴 Высокий

### Q2.2: Интеграции
**Вопрос:** Требуются ли внешние интеграции?
**Контекст:** Влияет на архитектуру
**Приоритет:** 🟡 Средний

---

## Раздел 3: Нефункциональные требования

### Q3.1: Производительность
**Вопрос:** Какие требования к времени отклика?
**Варианты:** <100ms, <200ms, <500ms, <1s
**Приоритет:** 🔴 Высокий

### Q3.2: Нагрузка
**Вопрос:** Ожидаемое количество пользователей?
**Контекст:** Влияет на масштабируемость
**Приоритет:** 🟡 Средний

---

## Раздел 6: Критерии успеха

### Q6.1: Метрики успеха
**Вопрос:** Как будет измеряться успех проекта?
**Контекст:** Необходимо для acceptance criteria
**Приоритет:** 🔴 Высокий

---

## Формат ответа

Пожалуйста, ответьте на вопросы в следующем формате:

\`\`\`
Q1.1: [Ваш ответ]
Q1.2: [Ваш ответ]
...
\`\`\`
EOF
    
    log_success "Вопросы сгенерированы: $questions_file"
}

# Обновление спецификации
update_spec() {
    local answers_file="$PROJECT_ROOT/specs/$SPEC_ID/clarification-answers.md"
    local changelog_file="$PROJECT_ROOT/specs/$SPEC_ID/spec-changelog.md"
    
    log_info "Подготовка к обновлению спецификации..."
    
    # Создание файла для ответов
    if [ ! -f "$answers_file" ]; then
        cat > "$answers_file" << EOF
# Clarification Answers

**Spec ID:** $SPEC_ID
**Дата:** $(date +%Y-%m-%d)

## Ответы на вопросы

<!-- Вставьте ответы здесь в формате:
Q1.1: [Ваш ответ]
Q1.2: [Ваш ответ]
-->

EOF
    fi
    
    # Создание changelog
    cat > "$changelog_file" << EOF
# Specification Changelog

**Spec ID:** $SPEC_ID

## История изменений

| Версия | Дата | Автор | Изменения |
|--------|------|-------|-----------|
| 1.0.0 | $(date +%Y-%m-%d) | | Initial version |
| 1.0.1 | $(date +%Y-%m-%d) | | Clarification updates |

## Изменения в версии 1.0.1

<!-- Будет заполнено после получения ответов -->

EOF
    
    log_success "Файлы для обновлений созданы"
}

# Обновление состояния
update_state() {
    local state_file="$PROJECT_ROOT/specs/$SPEC_ID/state.json"
    
    log_info "Обновление состояния..."
    
    if command -v jq &> /dev/null && [ -f "$state_file" ]; then
        jq '.phase = "clarify_complete" | .commands.clarify = "completed"' \
            "$state_file" > "$state_file.tmp" && mv "$state_file.tmp" "$state_file"
    fi
    
    log_success "Состояние обновлено"
}

# Основная функция
main() {
    SPEC_ID="${1:-}"
    
    if [ -z "$SPEC_ID" ]; then
        SPEC_ID=$(ls -t "$PROJECT_ROOT/specs/" 2>/dev/null | head -1)
        if [ -z "$SPEC_ID" ]; then
            log_error "SPEC_ID не указан и спецификации не найдены"
            exit 1
        fi
    fi
    
    echo "========================================"
    echo "  SpecKit: Clarify"
    echo "  Версия: 1.0.0"
    echo "  Spec ID: $SPEC_ID"
    echo "========================================"
    echo ""
    
    check_dependencies
    echo ""
    
    analyze_gaps
    echo ""
    
    generate_questions
    echo ""
    
    update_spec
    echo ""
    
    update_state
    echo ""
    
    log_success "========================================"
    log_success "  Уточнение инициировано!"
    log_success "  Файлы:"
    log_success "  - clarification-questions.md"
    log_success "  - clarification-answers.md (для ответов)"
    log_success "  Следующий шаг: После ответов запустить speckit.plan"
    log_success "========================================"
}

# Запуск
main "$@"
