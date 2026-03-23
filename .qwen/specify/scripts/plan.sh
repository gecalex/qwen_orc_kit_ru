#!/bin/bash
# SpecKit: Plan Script
# Назначение: Планирование реализации
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
    
    if [ ! -f "$PROJECT_ROOT/.qwen/specify/specs/$SPEC_ID/spec.md" ]; then
        log_error "spec.md не найден. Запустите сначала speckit.specify"
        exit 1
    fi
    
    log_success "Зависимости проверены"
}

# Создание plan.md
create_plan() {
    local plan_file="$PROJECT_ROOT/.qwen/specify/specs/$SPEC_ID/plan.md"
    
    log_info "Создание plan.md..."
    
    cat > "$plan_file" << EOF
# Implementation Plan: $PROJECT_NAME

**Spec ID:** $SPEC_ID
**Версия:** 1.0.0
**Дата:** $(date +%Y-%m-%d)
**Статус:** Draft

---

## Обзор плана

### Общая оценка
- **Минимальная:** 12 часов
- **Ожидаемая:** 20 часов
- **Максимальная:** 32 часа

### Фазы
| Фаза | Название | Длительность | Статус |
|------|----------|--------------|--------|
| 0 | Подготовка | 2 часа | Pending |
| 1 | Инфраструктура | 4 часа | Pending |
| 2 | Основные функции | 8 часов | Pending |
| 3 | Интеграции | 4 часа | Pending |
| 4 | Тестирование | 4 часа | Pending |
| 5 | Документирование | 2 часа | Pending |
| 6 | Релиз | 1 час | Pending |

---

## Фаза 0: Подготовка (2 часа)

### Задача 0.1: Настройка окружения
- **Описание:** Настройка development окружения
- **Оценка:** 30 минут
- **Зависимости:** Нет
- **Агент:** work_dev_specialist

### Задача 0.2: Инициализация репозитория
- **Описание:** Создание структуры проекта
- **Оценка:** 30 минут
- **Зависимости:** 0.1
- **Агент:** work_dev_specialist

### Задача 0.3: Конфигурация CI/CD
- **Описание:** Настройка pipeline
- **Оценка:** 1 час
- **Зависимости:** 0.2
- **Агент:** work_dev_specialist

---

## Фаза 1: Инфраструктура (4 часа)

### Задача 1.1: Создание базовой структуры
- **Описание:** Базовая архитектура проекта
- **Оценка:** 1.5 часа
- **Зависимости:** 0.3
- **Агент:** work_dev_specialist

### Задача 1.2: Настройка зависимостей
- **Описание:** Установка и конфигурация пакетов
- **Оценка:** 1 час
- **Зависимости:** 1.1
- **Агент:** work_dev_specialist

### Задача 1.3: Конфигурация линтеров
- **Описание:** Настройка ESLint, Prettier
- **Оценка:** 1.5 часа
- **Зависимости:** 1.2
- **Агент:** work_dev_specialist

---

## Фаза 2: Основные функции (8 часов)

### Задача 2.1: Реализация ядра
- **Описание:** Базовая бизнес-логика
- **Оценка:** 3 часа
- **Зависимости:** 1.3
- **Агент:** work_dev_specialist

### Задача 2.2: Реализация API
- **Описание:** REST/GraphQL endpoints
- **Оценка:** 3 часа
- **Зависимости:** 2.1
- **Агент:** work_dev_specialist

### Задача 2.3: Реализация UI
- **Описание:** Пользовательский интерфейс
- **Оценка:** 2 часа
- **Зависимости:** 2.2
- **Агент:** work_dev_specialist

---

## Фаза 3: Интеграции (4 часа)

### Задача 3.1: Внешние API
- **Описание:** Интеграция с внешними сервисами
- **Оценка:** 2 часа
- **Зависимости:** 2.2
- **Агент:** work_dev_specialist

### Задача 3.2: База данных
- **Описание:** Настройка и миграции
- **Оценка:** 2 часа
- **Зависимости:** 2.1
- **Агент:** work_dev_specialist

---

## Фаза 4: Тестирование (4 часа)

### Задача 4.1: Unit тесты
- **Описание:** Покрытие unit тестами
- **Оценка:** 2 часа
- **Зависимости:** 2.1, 2.2
- **Агент:** work_test_specialist

### Задача 4.2: Integration тесты
- **Описание:** End-to-end тестирование
- **Оценка:** 2 часа
- **Зависимости:** 3.1, 3.2
- **Агент:** work_test_specialist

---

## Фаза 5: Документирование (2 часа)

### Задача 5.1: API документация
- **Описание:** OpenAPI/Swagger spec
- **Оценка:** 1 час
- **Зависимости:** 2.2
- **Агент:** work_doc_writer

### Задача 5.2: README и guides
- **Описание:** Пользовательская документация
- **Оценка:** 1 час
- **Зависимости:** 2.3
- **Агент:** work_doc_writer

---

## Фаза 6: Релиз (1 час)

### Задача 6.1: Pre-release проверка
- **Описание:** Финальная валидация
- **Оценка:** 30 минут
- **Зависимости:** 4.1, 4.2, 5.1, 5.2
- **Агент:** work_test_specialist

### Задача 6.2: Публикация
- **Описание:** Release и deployment
- **Оценка:** 30 минут
- **Зависимости:** 6.1
- **Агент:** work_dev_specialist

---

## Граф зависимостей

\`\`\`
0.1 → 0.2 → 0.3 → 1.1 → 1.2 → 1.3 → 2.1 → 2.2 → 2.3
                              ↓      ↓      ↓
                            3.2    2.3    3.1
                              ↓      ↓      ↓
                            4.2 ← 4.1 ←───┘
                              ↓
                            5.1 → 5.2 → 6.1 → 6.2
\`\`\`

---

## Критический путь

0.1 → 0.2 → 0.3 → 1.1 → 1.2 → 1.3 → 2.1 → 2.2 → 2.3 → 4.1 → 5.1 → 5.2 → 6.1 → 6.2

**Длительность критического пути:** ~18 часов

---

## Риски плана

| Риск | Влияние | Вероятность | Митигация |
|------|---------|-------------|-----------|
| Задержки интеграции | Высокое | Средняя | Буфер в фазе 3 |
| Недостаточное тестирование | Высокое | Низкая | Автоматизация тестов |
| Изменение требований | Среднее | Средняя | Итеративный подход |
EOF
    
    log_success "plan.md создан: $plan_file"
}

# Создание timeline.md
create_timeline() {
    local timeline_file="$PROJECT_ROOT/.qwen/specify/specs/$SPEC_ID/timeline.md"
    
    log_info "Создание timeline.md..."
    
    cat > "$timeline_file" << EOF
# Project Timeline: $PROJECT_NAME

**Spec ID:** $SPEC_ID
**Дата создания:** $(date +%Y-%m-%d)

## Временная шкала

### Неделя 1
- День 1-2: Фаза 0 (Подготовка)
- День 3-4: Фаза 1 (Инфраструктура)
- День 5: Фаза 2 (Начало основных функций)

### Неделя 2
- День 1-3: Фаза 2 (Продолжение)
- День 4: Фаза 3 (Интеграции)
- День 5: Фаза 4 (Тестирование)

### Неделя 3
- День 1: Фаза 4 (Завершение)
- День 2: Фаза 5 (Документирование)
- День 3: Фаза 6 (Релиз)
- День 4-5: Буфер

## Вехи

| Веха | Дата | Описание |
|------|------|----------|
| M1 | День 2 | Завершение подготовки |
| M2 | День 4 | Инфраструктура готова |
| M3 | День 8 | Основные функции готовы |
| M4 | День 10 | Интеграции завершены |
| M5 | День 12 | Тестирование завершено |
| M6 | День 13 | Релиз |

## Gantt Chart (текстовый)

\`\`\`
Фаза 0: [██]
Фаза 1:    [████]
Фаза 2:         [████████]
Фаза 3:                    [████]
Фаза 4:                         [████]
Фаза 5:                              [██]
Фаза 6:                                [█]
     1  2  3  4  5  6  7  8  9 10 11 12 13
\`\`\`
EOF
    
    log_success "timeline.md создан: $timeline_file"
}

# Создание dependencies.md
create_dependencies() {
    local deps_file="$PROJECT_ROOT/.qwen/specify/specs/$SPEC_ID/dependencies.md"
    
    log_info "Создание dependencies.md..."
    
    cat > "$deps_file" << EOF
# Dependencies Matrix: $PROJECT_NAME

**Spec ID:** $SPEC_ID
**Дата:** $(date +%Y-%m-%d)

## Матрица зависимостей задач

| Задача | Зависит от | Блокирует | Тип |
|--------|------------|-----------|-----|
| 0.1 | - | 0.2 | Finish-to-Start |
| 0.2 | 0.1 | 0.3 | Finish-to-Start |
| 0.3 | 0.2 | 1.1 | Finish-to-Start |
| 1.1 | 0.3 | 1.2, 2.1 | Finish-to-Start |
| 1.2 | 1.1 | 1.3 | Finish-to-Start |
| 1.3 | 1.2 | 2.1 | Finish-to-Start |
| 2.1 | 1.3 | 2.2, 3.2 | Finish-to-Start |
| 2.2 | 2.1 | 2.3, 3.1 | Finish-to-Start |
| 2.3 | 2.2 | 5.2 | Finish-to-Start |
| 3.1 | 2.2 | 4.2 | Finish-to-Start |
| 3.2 | 2.1 | 4.2 | Finish-to-Start |
| 4.1 | 2.1, 2.2 | 6.1 | Finish-to-Start |
| 4.2 | 3.1, 3.2 | 6.1 | Finish-to-Start |
| 5.1 | 2.2 | 6.1 | Finish-to-Start |
| 5.2 | 2.3, 5.1 | 6.1 | Finish-to-Start |
| 6.1 | 4.1, 4.2, 5.1, 5.2 | 6.2 | Finish-to-Start |
| 6.2 | 6.1 | - | Finish-to-Start |

## Параллельные задачи

### Можно выполнять параллельно:
- 2.1 и 3.2 (после 1.3)
- 4.1 и 4.2 (частично)
- 5.1 и 5.2 (частично)

## Критический путь

\`\`\`
0.1 → 0.2 → 0.3 → 1.1 → 1.2 → 1.3 → 2.1 → 2.2 → 4.1 → 5.1 → 5.2 → 6.1 → 6.2
\`\`\`

**Длительность:** ~18 часов
**Запас времени:** 2 часа
EOF
    
    log_success "dependencies.md создан: $deps_file"
}

# Обновление состояния
update_state() {
    local state_file="$PROJECT_ROOT/.qwen/specify/specs/$SPEC_ID/state.json"
    
    log_info "Обновление состояния..."
    
    if command -v jq &> /dev/null && [ -f "$state_file" ]; then
        jq '.phase = "plan_complete" | .commands.plan = "completed"' \
            "$state_file" > "$state_file.tmp" && mv "$state_file.tmp" "$state_file"
    fi
    
    log_success "Состояние обновлено"
}

# Основная функция
main() {
    SPEC_ID="${1:-}"
    PROJECT_NAME="${2:-New Project}"
    
    if [ -z "$SPEC_ID" ]; then
        SPEC_ID=$(ls -t "$PROJECT_ROOT/.qwen/specify/specs/" 2>/dev/null | head -1)
        if [ -z "$SPEC_ID" ]; then
            log_error "SPEC_ID не указан и спецификации не найдены"
            exit 1
        fi
    fi
    
    echo "========================================"
    echo "  SpecKit: Plan"
    echo "  Версия: 1.0.0"
    echo "  Spec ID: $SPEC_ID"
    echo "========================================"
    echo ""
    
    check_dependencies
    echo ""
    
    create_plan
    echo ""
    
    create_timeline
    echo ""
    
    create_dependencies
    echo ""
    
    update_state
    echo ""
    
    log_success "========================================"
    log_success "  План создан!"
    log_success "  Файлы:"
    log_success "  - plan.md"
    log_success "  - timeline.md"
    log_success "  - dependencies.md"
    log_success "  Следующий шаг: speckit.implement"
    log_success "========================================"
}

# Запуск
main "$@"
