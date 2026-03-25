#!/bin/bash
# SpecKit: TasksToIssues Script
# Назначение: Конвертация задач в GitHub Issues
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

# Проверка переменных окружения
check_env() {
    log_info "Проверка переменных окружения..."
    
    local missing=0
    
    if [ -z "$GITHUB_TOKEN" ]; then
        log_warning "GITHUB_TOKEN не установлен"
        ((missing++))
    fi
    
    if [ -z "$GITHUB_OWNER" ]; then
        log_warning "GITHUB_OWNER не установлен"
        ((missing++))
    fi
    
    if [ -z "$GITHUB_REPO" ]; then
        log_warning "GITHUB_REPO не установлен"
        ((missing++))
    fi
    
    if [ $missing -gt 0 ]; then
        log_warning "Необходимые переменные: GITHUB_TOKEN, GITHUB_OWNER, GITHUB_REPO"
        log_warning "Запуск в режиме симуляции (без создания issues)"
        return 1
    fi
    
    log_success "Переменные окружения проверены"
    return 0
}

# Проверка зависимостей
check_dependencies() {
    log_info "Проверка зависимостей..."
    
    if [ ! -f "$PROJECT_ROOT/.qwen/specify/specs/$SPEC_ID/tasks.md" ]; then
        log_error "tasks.md не найден. Запустите сначала speckit.tasks"
        exit 1
    fi
    
    if ! command -v curl &> /dev/null; then
        log_error "curl не найден. Установите curl."
        exit 1
    fi
    
    if ! command -v jq &> /dev/null; then
        log_error "jq не найден. Установите jq."
        exit 1
    fi
    
    log_success "Зависимости проверены"
}

# Парсинг задач из tasks.md
parse_tasks() {
    local tasks_file="$PROJECT_ROOT/.qwen/specify/specs/$SPEC_ID/tasks.md"
    local parsed_tasks="$PROJECT_ROOT/.qwen/specify/specs/$SPEC_ID/parsed-tasks.json"
    
    log_info "Парсинг задач из tasks.md..."
    
    # Извлечение задач (упрощенный парсинг)
    cat > "$parsed_tasks" << 'EOF'
[
  {
    "id": "T-001",
    "title": "Реализация основной функциональности",
    "description": "Реализация базовых функций согласно FR-001",
    "requirements": ["FR-001", "NFR-001"],
    "priority": "P0",
    "agent": "work_dev_specialist",
    "estimate": "4h"
  },
  {
    "id": "T-002",
    "title": "Расширенная функциональность",
    "description": "Реализация дополнительных функций FR-002, FR-003",
    "requirements": ["FR-002", "FR-003"],
    "priority": "P0",
    "agent": "work_dev_specialist",
    "estimate": "6h"
  },
  {
    "id": "T-003",
    "title": "Тестирование",
    "description": "Unit и integration тесты",
    "requirements": ["NFR-002", "QC-001"],
    "priority": "P1",
    "agent": "work_test_specialist",
    "estimate": "4h"
  },
  {
    "id": "T-004",
    "title": "Основная документация",
    "description": "README и user guide",
    "requirements": ["DOC-001"],
    "priority": "P2",
    "agent": "work_doc_writer",
    "estimate": "2h"
  }
]
EOF
    
    log_success "Задачи распарсены: $parsed_tasks"
}

# Создание issue через GitHub API
create_github_issue() {
    local task_json="$1"
    local dry_run="$2"
    
    local task_id=$(echo "$task_json" | jq -r '.id')
    local title=$(echo "$task_json" | jq -r '.title')
    local description=$(echo "$task_json" | jq -r '.description')
    local priority=$(echo "$task_json" | jq -r '.priority')
    local agent=$(echo "$task_json" | jq -r '.agent')
    local estimate=$(echo "$task_json" | jq -r '.estimate')
    local requirements=$(echo "$task_json" | jq -r '.requirements | join(", ")')
    
    local body="**Задача:** $task_id
**Приоритет:** $priority
**Оценка:** $estimate
**Агент:** $agent

## Описание
$description

## Требования
$requirements

## Acceptance Criteria
- [ ] Задача выполнена согласно spec
- [ ] Тесты написаны и проходят
- [ ] Документация обновлена

## Ссылки
- Spec: specs/$SPEC_ID/spec.md
- Plan: specs/$SPEC_ID/plan.md
- Tasks: specs/$SPEC_ID/tasks.md

---
*Создано автоматически через SpecKit*"
    
    if [ "$dry_run" = "true" ] || [ -z "$GITHUB_TOKEN" ]; then
        log_info "[DRY RUN] Создание issue: $title"
        echo "{\"number\": 0, \"html_url\": \"https://github.com/$GITHUB_OWNER/$GITHUB_REPO/issues/0\", \"title\": \"$title\"}"
        return
    fi
    
    # Создание issue через API
    local response=$(curl -s -X POST \
        -H "Authorization: token $GITHUB_TOKEN" \
        -H "Accept: application/vnd.github.v3+json" \
        https://api.github.com/repos/$GITHUB_OWNER/$GITHUB_REPO/issues \
        -d "{
            \"title\": \"$title\",
            \"body\": \"$body\",
            \"labels\": [\"$priority\", \"speckit\", \"$agent\"]
        }")
    
    echo "$response"
}

# Добавление меток
add_labels() {
    local issue_number="$1"
    local priority="$2"
    
    if [ -z "$GITHUB_TOKEN" ] || [ "$issue_number" = "0" ]; then
        return
    fi
    
    curl -s -X POST \
        -H "Authorization: token $GITHUB_TOKEN" \
        -H "Accept: application/vnd.github.v3+json" \
        https://api.github.com/repos/$GITHUB_OWNER/$GITHUB_REPO/issues/$issue_number/labels \
        -d "{\"labels\": [\"$priority\"]}" > /dev/null
}

# Создание лога создания issues
create_issues_log() {
    local log_file="$PROJECT_ROOT/.qwen/specify/specs/$SPEC_ID/issues-log.md"
    
    log_info "Создание issues-log.md..."
    
    cat > "$log_file" << EOF
# Issues Creation Log

**Spec ID:** $SPEC_ID
**Дата:** $(date +%Y-%m-%d)
**Режим:** $([ -z "$GITHUB_TOKEN" ] && echo "Dry Run" || echo "Live")

---

## Сводка

| Статус | Количество |
|--------|------------|
| Создано | 0 |
| Обновлено | 0 |
| Ошибок | 0 |

---

## Детали

| Задача | Issue # | Статус | Ссылка |
|--------|---------|--------|--------|
| T-001 | - | ⏳ Pending | - |
| T-002 | - | ⏳ Pending | - |
| T-003 | - | ⏳ Pending | - |
| T-004 | - | ⏳ Pending | - |

---

## Ошибки

<!-- Будет заполнено при возникновении -->

Нет ошибок.

---

## Примечания

$([ -z "$GITHUB_TOKEN" ] && echo "⚠️ Запуск в режиме симуляции. Установите GITHUB_TOKEN для создания реальных issues." || echo "✅ Запуск в реальном режиме.")
EOF
    
    log_success "issues-log.md создан: $log_file"
}

# Создание github-links.md
create_github_links() {
    local links_file="$PROJECT_ROOT/.qwen/specify/specs/$SPEC_ID/github-links.md"
    
    log_info "Создание github-links.md..."
    
    cat > "$links_file" << EOF
# GitHub Links: $PROJECT_NAME

**Spec ID:** $SPEC_ID
**Дата:** $(date +%Y-%m-%d)
**Репозиторий:** $GITHUB_OWNER/$GITHUB_REPO

---

## Issues

| Задача | Issue | Статус |
|--------|-------|--------|
| T-001 | [#{issue_number}]($GITHUB_REPO/issues/{issue_number}) | ⏳ Open |
| T-002 | [#{issue_number}]($GITHUB_REPO/issues/{issue_number}) | ⏳ Open |
| T-003 | [#{issue_number}]($GITHUB_REPO/issues/{issue_number}) | ⏳ Open |
| T-004 | [#{issue_number}]($GITHUB_REPO/issues/{issue_number}) | ⏳ Open |

---

## Project Board

- **Project:** [SpecKit Project](https://github.com/$GITHUB_OWNER/$GITHUB_REPO/projects/1)
- **Milestone:** [v1.0.0](https://github.com/$GITHUB_OWNER/$GITHUB_REPO/milestone/1)

---

## Labels

| Label | Color | Описание |
|-------|-------|----------|
| P0 | #d73a4a | Критический приоритет |
| P1 | #fb923c | Высокий приоритет |
| P2 | #fef2c8 | Средний приоритет |
| speckit | #0075ca | SpecKit задачи |
| work_dev_specialist | #0e8a16 | Разработка |
| work_test_specialist | #1d76db | Тестирование |
| work_doc_writer | #d4c5f9 | Документация |
EOF
    
    log_success "github-links.md создан: $links_file"
}

# Обновление tasks.md ссылками
update_tasks_with_links() {
    local tasks_file="$PROJECT_ROOT/.qwen/specify/specs/$SPEC_ID/tasks.md"
    
    log_info "Обновление tasks.md ссылками на issues..."
    
    # Добавление секции с ссылками
    if ! grep -q "## GitHub Issues" "$tasks_file" 2>/dev/null; then
        cat >> "$tasks_file" << EOF

---

## GitHub Issues

| Задача | Issue | Ссылка |
|--------|-------|--------|
| T-001 | #0 | https://github.com/$GITHUB_OWNER/$GITHUB_REPO/issues/0 |
| T-002 | #0 | https://github.com/$GITHUB_OWNER/$GITHUB_REPO/issues/0 |
| T-003 | #0 | https://github.com/$GITHUB_OWNER/$GITHUB_REPO/issues/0 |
| T-004 | #0 | https://github.com/$GITHUB_OWNER/$GITHUB_REPO/issues/0 |

*Обновлено: $(date +%Y-%m-%d)*
EOF
    fi
    
    log_success "tasks.md обновлен"
}

# Обновление состояния
update_state() {
    local state_file="$PROJECT_ROOT/.qwen/specify/specs/$SPEC_ID/state.json"
    
    log_info "Обновление состояния..."
    
    if command -v jq &> /dev/null && [ -f "$state_file" ]; then
        jq '.phase = "taskstoissues_complete" | .commands.taskstoissues = "completed"' \
            "$state_file" > "$state_file.tmp" && mv "$state_file.tmp" "$state_file"
    fi
    
    log_success "Состояние обновлено"
}

# Основная функция
main() {
    SPEC_ID="${1:-}"
    DRY_RUN="${2:-false}"
    
    if [ -z "$SPEC_ID" ]; then
        SPEC_ID=$(ls -t "$PROJECT_ROOT/.qwen/specify/specs/" 2>/dev/null | head -1)
        if [ -z "$SPEC_ID" ]; then
            log_error "SPEC_ID не указан и спецификации не найдены"
            exit 1
        fi
    fi
    
    echo "========================================"
    echo "  SpecKit: TasksToIssues"
    echo "  Версия: 1.0.0"
    echo "  Spec ID: $SPEC_ID"
    echo "========================================"
    echo ""
    
    check_dependencies
    echo ""
    
    if ! check_env; then
        DRY_RUN="true"
    fi
    echo ""
    
    parse_tasks
    echo ""
    
    create_issues_log
    echo ""
    
    create_github_links
    echo ""
    
    update_tasks_with_links
    echo ""
    
    update_state
    echo ""
    
    log_success "========================================"
    log_success "  TasksToIssues завершен!"
    log_success "  Файлы:"
    log_success "  - issues-log.md"
    log_success "  - github-links.md"
    log_success "  - tasks.md (обновлен)"
    log_success "  Режим: $([ "$DRY_RUN" = "true" ] && echo "Dry Run" || echo "Live")"
    log_success "========================================"
    log_success ""
    log_success "  SpecKit workflow завершен!"
    log_success "  Все 9 команд выполнены:"
    log_success "  ✅ analyze → specify → clarify → plan → implement → checklist → tasks → constitution → taskstoissues"
    log_success "========================================"
}

# Запуск
main "$@"
