#!/bin/bash
# SpecKit: Tasks Script
# Назначение: Генерация задач и матрицы traceability
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
    
    if [ ! -f "$PROJECT_ROOT/specs/$SPEC_ID/spec.md" ]; then
        log_error "spec.md не найден. Запустите сначала speckit.specify"
        exit 1
    fi
    
    if [ ! -f "$PROJECT_ROOT/specs/$SPEC_ID/plan.md" ]; then
        log_error "plan.md не найден. Запустите сначала speckit.plan"
        exit 1
    fi
    
    if [ ! -f "$PROJECT_ROOT/specs/$SPEC_ID/checklist.md" ]; then
        log_warning "checklist.md не найден. Запустите speckit.checklist"
    fi
    
    log_success "Зависимости проверены"
}

# Создание tasks.md
create_tasks() {
    local tasks_file="$PROJECT_ROOT/specs/$SPEC_ID/tasks.md"
    
    log_info "Создание tasks.md..."
    
    cat > "$tasks_file" << EOF
# Tasks: $PROJECT_NAME

**Spec ID:** $SPEC_ID
**Версия:** 1.0.0
**Дата:** $(date +%Y-%m-%d)
**Статус:** Draft

---

## Матрица Traceability

| Задача | Требования | Статус | Приоритет | Агент | Оценка |
|--------|------------|--------|-----------|-------|--------|
| T-001 | FR-001, NFR-001 | Pending | P0 | work_dev_specialist | 4h |
| T-002 | FR-002, FR-003 | Pending | P0 | work_dev_specialist | 6h |
| T-003 | NFR-002, QC-001 | Pending | P1 | work_test_specialist | 4h |
| T-004 | DOC-001 | Pending | P2 | work_doc_writer | 2h |
| T-005 | FR-004, INT-001 | Pending | P0 | work_dev_specialist | 3h |
| T-006 | QC-002, QC-003 | Pending | P1 | work_test_specialist | 3h |
| T-007 | DOC-002, DOC-003 | Pending | P2 | work_doc_writer | 2h |
| T-008 | INT-002, AT-001 | Pending | P1 | work_test_specialist | 2h |

**Легенда приоритетов:**
- P0: Критический (должно быть в MVP)
- P1: Важный (должно быть в релизе)
- P2: Желательный (nice to have)

---

## Задачи P0 (Критические)

### T-001: Реализация основной функциональности
- **Описание:** Реализация базовых функций согласно FR-001
- **Требования:** FR-001, NFR-001
- **Оценка:** 4 часа
- **Агент:** work_dev_specialist
- **Зависимости:** Нет
- **Acceptance Criteria:**
  - [ ] Функция работает согласно spec
  - [ ] Производительность соответствует NFR-001
  - [ ] Тесты написаны и проходят

### T-002: Расширенная функциональность
- **Описание:** Реализация дополнительных функций FR-002, FR-003
- **Требования:** FR-002, FR-003
- **Оценка:** 6 часов
- **Агент:** work_dev_specialist
- **Зависимости:** T-001
- **Acceptance Criteria:**
  - [ ] Все функции реализованы
  - [ ] Интеграция с T-001 работает
  - [ ] Документация обновлена

### T-005: Интеграции
- **Описание:** Интеграция с внешними сервисами
- **Требования:** FR-004, INT-001
- **Оценка:** 3 часа
- **Агент:** work_dev_specialist
- **Зависимости:** T-001
- **Acceptance Criteria:**
  - [ ] Интеграции настроены
  - [ ] Обработка ошибок реализована
  - [ ] Логи добавлены

---

## Задачи P1 (Важные)

### T-003: Тестирование
- **Описание:** Unit и integration тесты
- **Требования:** NFR-002, QC-001
- **Оценка:** 4 часа
- **Агент:** work_test_specialist
- **Зависимости:** T-001, T-002
- **Acceptance Criteria:**
  - [ ] Coverage ≥ 80%
  - [ ] Все тесты проходят
  - [ ] CI pipeline настроен

### T-006: Качество кода
- **Описание:** Линтинг, типизация, рефакторинг
- **Требования:** QC-002, QC-003
- **Оценка:** 3 часа
- **Агент:** work_test_specialist
- **Зависимости:** T-001, T-002
- **Acceptance Criteria:**
  - [ ] Нет ошибок линтера
  - [ ] Нет ошибок TypeScript
  - [ ] Код отформатирован

### T-008: Acceptance тестирование
- **Описание:** End-to-end тестирование
- **Требования:** INT-002, AT-001
- **Оценка:** 2 часа
- **Агент:** work_test_specialist
- **Зависимости:** T-003, T-005
- **Acceptance Criteria:**
  - [ ] Все acceptance тесты проходят
  - [ ] Сценарии документированы

---

## Задачи P2 (Желательные)

### T-004: Основная документация
- **Описание:** README и user guide
- **Требования:** DOC-001
- **Оценка:** 2 часа
- **Агент:** work_doc_writer
- **Зависимости:** T-002
- **Acceptance Criteria:**
  - [ ] README полон
  - [ ] Примеры использования добавлены
  - [ ] Installation guide написан

### T-007: API документация
- **Описание:** OpenAPI/Swagger spec
- **Требования:** DOC-002, DOC-003
- **Оценка:** 2 часа
- **Агент:** work_doc_writer
- **Зависимости:** T-002
- **Acceptance Criteria:**
  - [ ] Все endpoints документированы
  - [ ] Примеры запросов/ответов
  - [ ] JSDoc комментарии добавлены

---

## Назначения агентов

| Агент | Задачи | Общая оценка |
|-------|--------|--------------|
| work_dev_specialist | T-001, T-002, T-005 | 13 часов |
| work_test_specialist | T-003, T-006, T-008 | 9 часов |
| work_doc_writer | T-004, T-007 | 4 часа |

---

## Прогресс выполнения

| Приоритет | Всего | Выполнено | В процессе | Ожидает |
|-----------|-------|-----------|------------|---------|
| P0 | 3 | 0 | 0 | 3 |
| P1 | 3 | 0 | 0 | 3 |
| P2 | 2 | 0 | 0 | 2 |
| **Итого** | **8** | **0** | **0** | **8** |

---

## История изменений

| Версия | Дата | Автор | Изменения |
|--------|------|-------|-----------|
| 1.0.0 | $(date +%Y-%m-%d) | | Initial version |
EOF
    
    log_success "tasks.md создан: $tasks_file"
}

# Создание traceability-matrix.md
create_traceability_matrix() {
    local matrix_file="$PROJECT_ROOT/specs/$SPEC_ID/traceability-matrix.md"
    
    log_info "Создание traceability-matrix.md..."
    
    cat > "$matrix_file" << EOF
# Traceability Matrix: $PROJECT_NAME

**Spec ID:** $SPEC_ID
**Дата:** $(date +%Y-%m-%d)

---

## Требования → Задачи

| Требование | Задачи | Статус покрытия |
|------------|--------|-----------------|
| FR-001 | T-001 | ✅ Покрыто |
| FR-002 | T-002 | ✅ Покрыто |
| FR-003 | T-002 | ✅ Покрыто |
| FR-004 | T-005 | ✅ Покрыто |
| NFR-001 | T-001 | ✅ Покрыто |
| NFR-002 | T-003 | ✅ Покрыто |
| QC-001 | T-003, T-006 | ✅ Покрыто |
| QC-002 | T-006 | ✅ Покрыто |
| QC-003 | T-006 | ✅ Покрыто |
| DOC-001 | T-004 | ✅ Покрыто |
| DOC-002 | T-007 | ✅ Покрыто |
| DOC-003 | T-007 | ✅ Покрыто |
| INT-001 | T-005 | ✅ Покрыто |
| INT-002 | T-008 | ✅ Покрыто |
| AT-001 | T-008 | ✅ Покрыто |

---

## Задачи → Требования

| Задача | Покрытые требования | Приоритет |
|--------|---------------------|-----------|
| T-001 | FR-001, NFR-001 | P0 |
| T-002 | FR-002, FR-003 | P0 |
| T-003 | NFR-002, QC-001 | P1 |
| T-004 | DOC-001 | P2 |
| T-005 | FR-004, INT-001 | P0 |
| T-006 | QC-002, QC-003 | P1 |
| T-007 | DOC-002, DOC-003 | P2 |
| T-008 | INT-002, AT-001 | P1 |

---

## Задачи → Acceptance Criteria

| Задача | Acceptance Criteria | Статус |
|--------|---------------------|--------|
| T-001 | AC-FR-001, AC-NFR-001 | ⏳ Pending |
| T-002 | AC-FR-002, AC-FR-003 | ⏳ Pending |
| T-003 | AC-NFR-002, AC-QC-001 | ⏳ Pending |
| T-004 | AC-DOC-001 | ⏳ Pending |
| T-005 | AC-FR-004, AC-INT-001 | ⏳ Pending |
| T-006 | AC-QC-002, AC-QC-003 | ⏳ Pending |
| T-007 | AC-DOC-002, AC-DOC-003 | ⏳ Pending |
| T-008 | AC-INT-002, AC-AT-001 | ⏳ Pending |

---

## Анализ покрытия

### Покрытие требований
- **Всего требований:** 15
- **Покрыто задачами:** 15
- **Не покрыто:** 0
- **Процент покрытия:** 100%

### Покрытие acceptance criteria
- **Всего критериев:** 8
- **Покрыто тестами:** 8
- **Не покрыто:** 0
- **Процент покрытия:** 100%

---

## Непокрытые элементы

<!-- Список непокрытых требований (если есть) -->

Нет непокрытых элементов.

---

## Рекомендации

1. Все требования покрыты задачами
2. Все acceptance criteria имеют соответствующие тесты
3. Поддерживайте актуальность матрицы при изменениях
EOF
    
    log_success "traceability-matrix.md создан: $matrix_file"
}

# Создание agent-assignments.md
create_agent_assignments() {
    local assignments_file="$PROJECT_ROOT/specs/$SPEC_ID/agent-assignments.md"
    
    log_info "Создание agent-assignments.md..."
    
    cat > "$assignments_file" << EOF
# Agent Assignments: $PROJECT_NAME

**Spec ID:** $SPEC_ID
**Дата:** $(date +%Y-%m-%d)

---

## Назначения по агентам

### work_dev_specialist
**Роль:** Разработка
**Задачи:** T-001, T-002, T-005
**Общая оценка:** 13 часов
**Приоритет:** Высокий

#### Задачи:
1. **T-001:** Реализация основной функциональности (4h)
2. **T-002:** Расширенная функциональность (6h)
3. **T-005:** Интеграции (3h)

#### Контекст:
- Спецификация: specs/$SPEC_ID/spec.md
- План: specs/$SPEC_ID/plan.md
- Конституция: specs/$SPEC_ID/constitution.md

---

### work_test_specialist
**Роль:** Тестирование
**Задачи:** T-003, T-006, T-008
**Общая оценка:** 9 часов
**Приоритет:** Высокий

#### Задачи:
1. **T-003:** Тестирование (4h)
2. **T-006:** Качество кода (3h)
3. **T-008:** Acceptance тестирование (2h)

#### Контекст:
- Чек-лист: specs/$SPEC_ID/checklist.md
- Acceptance тесты: specs/$SPEC_ID/acceptance-tests.md

---

### work_doc_writer
**Роль:** Документирование
**Задачи:** T-004, T-007
**Общая оценка:** 4 часа
**Приоритет:** Средний

#### Задачи:
1. **T-004:** Основная документация (2h)
2. **T-007:** API документация (2h)

#### Контекст:
- Спецификация: specs/$SPEC_ID/spec.md
- Требования к документации: specs/$SPEC_ID/checklist.md#4-Документация

---

## Балансировка нагрузки

| Агент | Задач | Часов | Загрузка |
|-------|-------|-------|----------|
| work_dev_specialist | 3 | 13 | Высокая |
| work_test_specialist | 3 | 9 | Средняя |
| work_doc_writer | 2 | 4 | Низкая |

---

## Последовательность выполнения

\`\`\`
День 1-2: work_dev_specialist (T-001, T-002 начало)
День 3:   work_dev_specialist (T-002 завершение, T-005)
          work_test_specialist (T-003 начало)
День 4:   work_test_specialist (T-003 завершение, T-006)
          work_doc_writer (T-004)
День 5:   work_test_specialist (T-008)
          work_doc_writer (T-007)
\`\`\`

---

## Контакты и эскалация

| Роль | Агент | Эскалация |
|------|-------|-----------|
| Разработка | work_dev_specialist | work_dev_lead |
| Тестирование | work_test_specialist | work_qa_lead |
| Документация | work_doc_writer | work_doc_lead |
EOF
    
    log_success "agent-assignments.md создан: $assignments_file"
}

# Создание priority-board.md
create_priority_board() {
    local board_file="$PROJECT_ROOT/specs/$SPEC_ID/priority-board.md"
    
    log_info "Создание priority-board.md..."
    
    cat > "$board_file" << EOF
# Priority Board: $PROJECT_NAME

**Spec ID:** $SPEC_ID
**Дата:** $(date +%Y-%m-%d)
**Обновлено:** $(date +%Y-%m-%d\ %H:%M)

---

## 📊 Доска приоритетов

### P0 - Критические (Must Have)

| Задача | Описание | Агент | Оценка | Статус |
|--------|----------|-------|--------|--------|
| T-001 | Основная функциональность | work_dev_specialist | 4h | ⏳ To Do |
| T-002 | Расширенная функциональность | work_dev_specialist | 6h | ⏳ To Do |
| T-005 | Интеграции | work_dev_specialist | 3h | ⏳ To Do |

**Всего:** 13 часов

---

### P1 - Важные (Should Have)

| Задача | Описание | Агент | Оценка | Статус |
|--------|----------|-------|--------|--------|
| T-003 | Тестирование | work_test_specialist | 4h | ⏳ To Do |
| T-006 | Качество кода | work_test_specialist | 3h | ⏳ To Do |
| T-008 | Acceptance тестирование | work_test_specialist | 2h | ⏳ To Do |

**Всего:** 9 часов

---

### P2 - Желательные (Nice to Have)

| Задача | Описание | Агент | Оценка | Статус |
|--------|----------|-------|--------|--------|
| T-004 | Основная документация | work_doc_writer | 2h | ⏳ To Do |
| T-007 | API документация | work_doc_writer | 2h | ⏳ To Do |

**Всего:** 4 часа

---

## 📈 Прогресс

### По приоритетам

| Приоритет | Прогресс |
|-----------|----------|
| P0 | [░░░░░░░░░░] 0% (0/3) |
| P1 | [░░░░░░░░░░] 0% (0/3) |
| P2 | [░░░░░░░░░░] 0% (0/2) |

### Общий прогресс

**Общий:** [░░░░░░░░░░] 0% (0/8 задач, 0/26 часов)

---

## 🎯 Следующие задачи

1. **T-001** - Начать разработку основной функциональности
2. **T-002** - После завершения T-001
3. **T-005** - После завершения T-001

---

## 📅 Timeline

\`\`\`
Неделя 1:
├─ P0: T-001, T-002, T-005 (13h)
└─ P1: T-003 начало (2h)

Неделя 2:
├─ P1: T-003 завершение, T-006, T-008 (7h)
└─ P2: T-004, T-007 (4h)
\`\`\`
EOF
    
    log_success "priority-board.md создан: $board_file"
}

# Обновление состояния
update_state() {
    local state_file="$PROJECT_ROOT/specs/$SPEC_ID/state.json"
    
    log_info "Обновление состояния..."
    
    if command -v jq &> /dev/null && [ -f "$state_file" ]; then
        jq '.phase = "tasks_complete" | .commands.tasks = "completed"' \
            "$state_file" > "$state_file.tmp" && mv "$state_file.tmp" "$state_file"
    fi
    
    log_success "Состояние обновлено"
}

# Основная функция
main() {
    SPEC_ID="${1:-}"
    PROJECT_NAME="${2:-New Project}"
    
    if [ -z "$SPEC_ID" ]; then
        SPEC_ID=$(ls -t "$PROJECT_ROOT/specs/" 2>/dev/null | head -1)
        if [ -z "$SPEC_ID" ]; then
            log_error "SPEC_ID не указан и спецификации не найдены"
            exit 1
        fi
    fi
    
    echo "========================================"
    echo "  SpecKit: Tasks"
    echo "  Версия: 1.0.0"
    echo "  Spec ID: $SPEC_ID"
    echo "========================================"
    echo ""
    
    check_dependencies
    echo ""
    
    create_tasks
    echo ""
    
    create_traceability_matrix
    echo ""
    
    create_agent_assignments
    echo ""
    
    create_priority_board
    echo ""
    
    update_state
    echo ""
    
    log_success "========================================"
    log_success "  Задачи сгенерированы!"
    log_success "  Файлы:"
    log_success "  - tasks.md"
    log_success "  - traceability-matrix.md"
    log_success "  - agent-assignments.md"
    log_success "  - priority-board.md"
    log_success "  Следующий шаг: speckit.constitution"
    log_success "========================================"
}

# Запуск
main "$@"
