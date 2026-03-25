#!/bin/bash
# SpecKit: Tasks Project Script
# Назначение: Генерация ОДНОГО tasks.md на ВСЁ проект
# Версия: 2.0.0

set -e

# Конфигурация
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SPECIFY_DIR="$(dirname "$SCRIPT_DIR")"
PROJECT_ROOT="$(dirname "$(dirname "$SPECIFY_DIR")")"
TASKS_FILE="$SPECIFY_DIR/tasks.md"

# Цвета
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Проверка зависимостей
check_dependencies() {
    log_info "Проверка зависимостей..."
    
    if [ ! -f "$SPECIFY_DIR/plan.md" ]; then
        log_error "plan.md не найден. Запустите сначала speckit.plan"
        exit 1
    fi
    
    if [ ! -f "$SPECIFY_DIR/data-model.md" ]; then
        log_error "data-model.md не найден. Запустите сначала speckit.plan"
        exit 1
    fi
    
    # Проверка спецификаций модулей (пропускаем 000-constitution)
    local spec_count=0
    for spec_dir in "$SPECIFY_DIR"/specs/*/; do
        if [ -d "$spec_dir" ]; then
            local dir_name=$(basename "$spec_dir")
            
            # Пропускаем 000-constitution (это не модуль)
            if [ "$dir_name" = "000-constitution" ]; then
                continue
            fi
            
            if [ ! -f "$spec_dir/spec.md" ]; then
                log_error "spec.md не найден в $spec_dir"
                exit 1
            fi
            ((spec_count++)) || true
        fi
    done
    
    if [ $spec_count -eq 0 ]; then
        log_error "Спецификации не найдены. Запустите сначала speckit.specify"
        exit 1
    fi
    
    log_success "Найдено спецификаций: $spec_count"
    log_success "Зависимости проверены"
}

# Генерация tasks.md
generate_tasks() {
    log_info "Генерация ОДНОГО tasks.md на ВСЁ проект..."
    
    # Извлечь данные из plan.md
    local project_name=$(grep "^# " "$SPECIFY_DIR/plan.md" | head -1 | sed 's/# //')
    
    # Создать tasks.md
    cat > "$TASKS_FILE" << EOF
# Tasks: $project_name

**Версия:** 2.0.0  
**Дата:** $(date +%Y-%m-%d)  
**Статус:** Draft  
**Тип:** ОБЩИЙ план на ВСЁ проект

---

## Dependency Graph

\`\`\`
004-api (Infra/Auth) ← ПЕРВЫЙ
    ↓
001-notes (Core DB)
    ↓
002-search (Search)
    ↓
003-export-import (Export)
\`\`\`

**Критический путь:** 004-api → 001-notes → 002-search → 003-export-import = 10 недель

---

## Задачи по модулям

EOF

    # Для каждого модуля
    for spec_dir in "$SPECIFY_DIR"/specs/*/; do
        if [ -d "$spec_dir" ]; then
            local module_name=$(basename "$spec_dir")
            local module_id=$(echo "$module_name" | cut -d'-' -f1)
            
            echo "### Модуль $module_name" >> "$TASKS_FILE"
            echo "" >> "$TASKS_FILE"
            echo "| ID | Задача | Зависимости | Роль | Оценка |" >> "$TASKS_FILE"
            echo "|----|--------|-------------|------|--------|" >> "$TASKS_FILE"
            echo "| T-${module_id}-001 | Задача 1 | - | Backend | 4h |" >> "$TASKS_FILE"
            echo "" >> "$TASKS_FILE"
        fi
    done
    
    # Добавить итог
    cat >> "$TASKS_FILE" << EOF

## Итого

- **Всего задач:** {COUNT}
- **Всего часов:** {HOURS}
- **Критический путь:** из plan.md

---

## Traceability Matrix

| Задача | Требования | Статус | Приоритет |
|--------|------------|--------|-----------|
| T-001 | FR-001 | Pending | P0 |
EOF
    
    log_success "tasks.md создан: $TASKS_FILE"
}

# Main
main() {
    log_info "=== Speckit Tasks Project ==="
    check_dependencies
    generate_tasks
    log_success "Генерация задач завершена"
}

main "$@"
