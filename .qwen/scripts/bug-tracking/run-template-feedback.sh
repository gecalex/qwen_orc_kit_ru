#!/bin/bash

# =============================================================================
# run-template-feedback.sh - Запуск сбора обратной связи о ШАБЛОНЕ
# =============================================================================
# Назначение: Автоматический запуск сбора обратной связи о ШАБЛОНЕ
# 
# Функционал:
#   - Запуск тестов
#   - Фильтрация ошибок ШАБЛОНА (только .qwen/...)
#   - Создание отчёта
#   - Отправка в ШАБЛОН
#
# ВАЖНО: БЕЗ HARDCODE! Универсально для любого проекта.
#
# Использование:
#   .qwen/scripts/bug-tracking/run-template-feedback.sh
# =============================================================================

set -e

# -----------------------------------------------------------------------------
# Инициализация
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# PROJECT_ROOT — корень проекта (где находится .qwen/)
# Если скрипт в .qwen/scripts/bug-tracking/, то PROJECT_ROOT = ../../..
PROJECT_ROOT="$SCRIPT_DIR/../../.."

# Цвета
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# -----------------------------------------------------------------------------
# Функции
# -----------------------------------------------------------------------------

log_info() {
  echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
  echo -e "${GREEN}[OK]${NC} $1"
}

log_warning() {
  echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
  echo -e "${RED}[ERROR]${NC} $1"
}

# Инициализация директорий
init_directories() {
  log_info "Инициализация директорий..."
  
  mkdir -p "$PROJECT_ROOT/.qwen/state/bugs"
  mkdir -p "$PROJECT_ROOT/.qwen/state/feedback"
  mkdir -p "$PROJECT_ROOT/.qwen/state/feedback/inbox"
  mkdir -p "$PROJECT_ROOT/.qwen/state/feedback/processed"
  
  # Инициализировать реестр
  if [ ! -f "$PROJECT_ROOT/.qwen/state/template-feedback-registry.json" ]; then
    echo '{"bugs": []}' > "$PROJECT_ROOT/.qwen/state/template-feedback-registry.json"
  fi
  
  log_success "Директории созданы"
}

# Запуск тестов
run_tests() {
  log_info "Запуск тестов..."
  
  cd "$PROJECT_ROOT"
  
  # Запустить тесты и сохранить вывод
  pytest tests/ -v --tb=line 2>&1 | tee /tmp/pytest-output.txt
  
  log_success "Тесты завершены"
}

# Парсинг результатов
parse_results() {
  log_info "Парсинг результатов..."
  
  local output_file="/tmp/pytest-output.txt"
  
  # Подсчитать failed, errors, warnings
  FAILED=$(grep -c "FAILED" "$output_file" 2>/dev/null | tr -d '\n' || echo "0")
  ERRORS=$(grep -c "ERROR" "$output_file" 2>/dev/null | tr -d '\n' || echo "0")
  WARNINGS=$(grep -c "warnings summary" "$output_file" 2>/dev/null | tr -d '\n' || echo "0")
  
  # Извлечь детали failed тестов
  FAILED_TESTS=$(grep "FAILED\|ERROR" "$output_file" | head -20)
  
  log_success "Результаты: Failed=$FAILED, Errors=$ERRORS, Warnings=$WARNINGS"
}

# Фильтр: Оставить только ошибки ШАБЛОНА
filter_template_bugs() {
  local failed_tests="$1"
  
  log_info "Фильтрация ошибок ШАБЛОНА..."
  
  # Оставить только ошибки в компонентах ШАБЛОНА
  echo "$failed_tests" | while read -r line; do
    # Проверить что это ошибка ШАБЛОНА
    if echo "$line" | grep -qE "\.qwen/(scripts|agents|skills|templates)/"; then
      echo "$line"
    fi
  done
}

# Создание отчёта
create_report() {
  local template_bugs="$1"
  local failed="$2"
  local errors="$3"
  local warnings="$4"
  
  log_info "Создание отчёта..."
  
  # Проверить: есть ли ошибки ШАБЛОНА
  if [ -z "$template_bugs" ] || [ "$template_bugs" = "" ]; then
    log_info "Ошибки ШАБЛОНА не найдены — отчёт не создаётся"
    return 0
  fi
  
  local bug_id="P2-$(date +%Y%m%d-%H%M%S)"
  local bug_file="$PROJECT_ROOT/.qwen/state/bugs/${bug_id}.md"
  
  cat > "$bug_file" << EOF
---
bug_id: $bug_id
priority: P2
priority_label: Medium
status: open
created: $(date -Iseconds)
project: qwen_orc_kit_ru
project_type: template
source: auto-detection
template_component: true
---

# Template Bug Report: $bug_id

## Description
Автоматически обнаружена ошибка в ШАБЛОНЕ (НЕ в проекте!)

## Template Bugs Only
$template_bugs

## Test Results (все)
- Failed: $failed
- Errors: $errors
- Warnings: $warnings

## Recommended Action
Запустить bug-hunter для анализа ошибки ШАБЛОНА

## Metadata
- Bug File: $bug_file
- Template Component: true
EOF

  log_success "Отчёт создан: $bug_file"
  echo "$bug_file"
}

# Обновление реестра
update_registry() {
  local bug_id="$1"
  
  log_info "Обновление реестра..."
  
  local registry_file="$PROJECT_ROOT/.qwen/state/template-feedback-registry.json"
  
  if [ ! -f "$registry_file" ]; then
    echo '{"bugs": []}' > "$registry_file"
  fi
  
  # Обновить реестр
  jq --arg id "$bug_id" \
     '.bugs += [{"bug_id": $id, "priority": "P2", "status": "open", "created": "'"$(date -Iseconds)"'"}]' \
     "$registry_file" > "${registry_file}.tmp"
  mv "${registry_file}.tmp" "$registry_file"
  
  log_success "Реестр обновлён"
}

# Отправка в ШАБЛОН
send_to_template() {
  local bug_file="$1"
  
  log_info "Отправка в ШАБЛОН..."
  
  if [ -f "$SCRIPT_DIR/send-template-feedback.sh" ]; then
    "$SCRIPT_DIR/send-template-feedback.sh" "$bug_file"
    log_success "Отчёт отправлен в ШАБЛОН"
  else
    log_warning "send-template-feedback.sh не найден"
  fi
}

# -----------------------------------------------------------------------------
# Основная функция
# -----------------------------------------------------------------------------

main() {
  echo -e "${BLUE}========================================${NC}"
  echo -e "${BLUE}  Сбор обратной связи о ШАБЛОНЕ${NC}"
  echo -e "${BLUE}========================================${NC}"
  echo ""
  
  # Инициализация
  init_directories
  
  # Запуск тестов
  run_tests
  
  # Парсинг результатов
  parse_results
  
  # Фильтрация ошибок ШАБЛОНА
  TEMPLATE_BUGS=$(filter_template_bugs "$FAILED_TESTS")
  
  # Создание отчёта
  if [ -n "$TEMPLATE_BUGS" ] && [ "$TEMPLATE_BUGS" != "" ]; then
    BUG_FILE=$(create_report "$TEMPLATE_BUGS" "$FAILED" "$ERRORS" "$WARNINGS")
    
    # Обновление реестра
    if [ -n "$BUG_FILE" ]; then
      local bug_id=$(basename "$BUG_FILE" .md)
      update_registry "$bug_id"
      
      # Отправка в ШАБЛОН
      send_to_template "$BUG_FILE"
    fi
  else
    log_info "Ошибки ШАБЛОНА не найдены"
  fi
  
  echo ""
  echo -e "${GREEN}✅ Сбор обратной связи завершён${NC}"
  echo ""
  echo "Отчёты: $PROJECT_ROOT/.qwen/state/bugs/"
  echo "Реестр: $PROJECT_ROOT/.qwen/state/template-feedback-registry.json"
}

# Запуск
main "$@"
