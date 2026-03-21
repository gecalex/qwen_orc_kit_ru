#!/bin/bash
# SpecKit: Specify Script
# Назначение: Создание спецификации проекта
# Версия: 1.0.0

set -e

# Конфигурация
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SPECIFY_DIR="$(dirname "$SCRIPT_DIR")"
PROJECT_ROOT="$(dirname "$(dirname "$SPECIFY_DIR")")"
TEMPLATES_DIR="$SPECIFY_DIR/templates"
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
    
    if [ ! -f "$PROJECT_ROOT/specs/$SPEC_ID/requirements.md" ]; then
        log_error "requirements.md не найден. Запустите сначала speckit.analyze"
        exit 1
    fi
    
    log_success "Зависимости проверены"
}

# Создание spec.md
create_spec() {
    local spec_file="$PROJECT_ROOT/specs/$SPEC_ID/spec.md"
    
    log_info "Создание spec.md..."
    
    # Проверка наличия шаблона
    local template="$TEMPLATES_DIR/spec-template.md"
    if [ ! -f "$template" ]; then
        log_warning "Шаблон не найден, используем шаблон по умолчанию"
    fi
    
    cat > "$spec_file" << EOF
# Specification: $PROJECT_NAME

**Spec ID:** $SPEC_ID
**Версия:** 1.0.0
**Дата:** $(date +%Y-%m-%d)
**Статус:** Draft

---

## 1. Обзор проекта

### 1.1 Цель
<!-- Цель проекта -->

### 1.2 Контекст
<!-- Контекст и предыстория -->

### 1.3 Стейкхолдеры
| Роль | Имя | Ответственность |
|------|-----|-----------------|
| Product Owner | | |
| Tech Lead | | |
| Developer | | |

---

## 2. Функциональные требования

| ID | Требование | Приоритет | Статус |
|----|------------|-----------|--------|
| FR-001 | | P0 | Pending |
| FR-002 | | P0 | Pending |

---

## 3. Нефункциональные требования

| ID | Требование | Метрика | Целевое значение |
|----|------------|---------|------------------|
| NFR-001 | Производительность | Время отклика | < 200ms |
| NFR-002 | Масштабируемость | Одновременные пользователи | 1000+ |
| NFR-003 | Безопасность | Уязвимости | 0 критических |

---

## 4. Ограничения

### 4.1 Технические ограничения
- 

### 4.2 Временные ограничения
- 

### 4.3 Ресурсные ограничения
- 

---

## 5. Предположения

| ID | Предположение | Влияние | Риск |
|----|---------------|---------|------|
| A-001 | | | |

---

## 6. Критерии успеха

| ID | Критерий | Метрика | Целевое значение |
|----|----------|---------|------------------|
| SC-001 | | | |
| SC-002 | | | |

---

## 7. Архитектурные решения

### 7.1 Высокоуровневая архитектура
<!-- Диаграмма или описание архитектуры -->

### 7.2 Компоненты
| Компонент | Описание | Технологии |
|-----------|----------|------------|
| | | |

### 7.3 Взаимодействия
<!-- Описание взаимодействий между компонентами -->

---

## 8. Интерфейсы

### 8.1 API
<!-- Описание API endpoints -->

### 8.2 Пользовательский интерфейс
<!-- Описание UI компонентов -->

### 8.3 Интеграции
<!-- Описание внешних интеграций -->

---

## 9. Риски

| ID | Риск | Вероятность | Влияние | Митигация |
|----|------|-------------|---------|-----------|
| R-001 | | Низкая/Средняя/Высокая | Низкое/Среднее/Высокое | |

---

## Приложения

### A. Глоссарий
| Термин | Определение |
|--------|-------------|
| | |

### B. Ссылки
- 

### C. История изменений
| Версия | Дата | Автор | Изменения |
|--------|------|-------|-----------|
| 1.0.0 | $(date +%Y-%m-%d) | | Initial version |
EOF
    
    log_success "spec.md создан: $spec_file"
}

# Создание резюме
create_summary() {
    local summary_file="$PROJECT_ROOT/specs/$SPEC_ID/spec-summary.md"
    
    log_info "Создание резюме спецификации..."
    
    cat > "$summary_file" << EOF
# Specification Summary: $PROJECT_NAME

**Spec ID:** $SPEC_ID
**Дата:** $(date +%Y-%m-%d)

## Краткое описание
<!-- 2-3 предложения о проекте -->

## Ключевые требования
1. 
2. 
3. 

## Критерии успеха
1. 
2. 
3. 

## Основные риски
1. 
2. 

## Следующие шаги
1. Запустить \`speckit.clarify\` для уточнения деталей
2. Запустить \`speckit.plan\` для планирования
EOF
    
    log_success "Резюме создано: $summary_file"
}

# Создание глоссария
create_glossary() {
    local glossary_file="$PROJECT_ROOT/specs/$SPEC_ID/glossary.md"
    
    log_info "Создание глоссария..."
    
    cat > "$glossary_file" << EOF
# Glossary: $PROJECT_NAME

**Spec ID:** $SPEC_ID
**Дата:** $(date +%Y-%m-%d)

## Термины и определения

| Термин | Определение | Контекст |
|--------|-------------|----------|
| SpecKit | Specification-driven development toolkit | Проект |
| Spec | Спецификация проекта | Документ |
| Phase | Фаза разработки | Процесс |

## Аббревиатуры

| Аббревиатура | Расшифровка |
|--------------|-------------|
| API | Application Programming Interface |
| UI | User Interface |
| NFR | Non-Functional Requirement |
| FR | Functional Requirement |
EOF
    
    log_success "Глоссарий создан: $glossary_file"
}

# Обновление состояния
update_state() {
    local state_file="$PROJECT_ROOT/specs/$SPEC_ID/state.json"
    
    log_info "Обновление состояния..."
    
    if command -v jq &> /dev/null && [ -f "$state_file" ]; then
        jq '.phase = "specify_complete" | .commands.specify = "completed"' \
            "$state_file" > "$state_file.tmp" && mv "$state_file.tmp" "$state_file"
    fi
    
    log_success "Состояние обновлено"
}

# Основная функция
main() {
    SPEC_ID="${1:-}"
    PROJECT_NAME="${2:-New Project}"
    
    if [ -z "$SPEC_ID" ]; then
        # Поиск последней спецификации
        SPEC_ID=$(ls -t "$PROJECT_ROOT/specs/" 2>/dev/null | head -1)
        if [ -z "$SPEC_ID" ]; then
            log_error "SPEC_ID не указан и спецификации не найдены"
            exit 1
        fi
    fi
    
    echo "========================================"
    echo "  SpecKit: Specify"
    echo "  Версия: 1.0.0"
    echo "  Spec ID: $SPEC_ID"
    echo "========================================"
    echo ""
    
    check_dependencies
    echo ""
    
    create_spec
    echo ""
    
    create_summary
    echo ""
    
    create_glossary
    echo ""
    
    update_state
    echo ""
    
    log_success "========================================"
    log_success "  Спецификация создана!"
    log_success "  Следующий шаг: speckit.clarify"
    log_success "========================================"
}

# Запуск
main "$@"
