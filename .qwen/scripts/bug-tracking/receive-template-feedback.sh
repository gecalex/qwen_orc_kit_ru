#!/bin/bash

# =============================================================================
# receive-bug-report.sh - Приём отчётов о багах из ПРОЕКТОВ
# =============================================================================
# Назначение: Приём отчётов о багах от ПРОЕКТОВ и обработка для исправления
# 
# Функционал:
#   - Приём отчётов в inbox директорию
#   - Обработка и валидация отчётов
#   - Перемещение в processed директорию
#   - Обновление feedback-registry.json
#
# ВАЖНО: БЕЗ HARDCODE! Универсально для любого проекта.
#
# Использование:
#   .qwen/scripts/bug-tracking/receive-bug-report.sh [report_file]
# =============================================================================

set -e

# -----------------------------------------------------------------------------
# Инициализация
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../config.sh"

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
  mkdir -p "$FEEDBACK_DIR/inbox"
  mkdir -p "$FEEDBACK_DIR/processed"
  mkdir -p "$FEEDBACK_DIR/errors"
}

# Валидация отчёта
validate_report() {
  local report_file="$1"
  
  log_info "Валидация отчёта..."
  
  # Проверить наличие обязательных полей
  local required_fields=("bug_id:" "priority:" "status:" "created:")
  
  for field in "${required_fields[@]}"; do
    if ! grep -q "^$field" "$report_file"; then
      log_error "Отсутствует обязательное поле: $field"
      return 1
    fi
  done
  
  log_success "Отчёт валиден"
  return 0
}

# Извлечение метаданных
extract_metadata() {
  local report_file="$1"
  
  BUG_ID=$(grep "^bug_id:" "$report_file" | cut -d':' -f2 | tr -d ' ')
  PRIORITY=$(grep "^priority:" "$report_file" | cut -d':' -f2 | tr -d ' ')
  PROJECT=$(grep "^project:" "$report_file" | cut -d':' -f2 | tr -d ' ')
  CREATED=$(grep "^created:" "$report_file" | cut -d':' -f2 | tr -d ' ')
  
  log_info "Метаданные: BugID=$BUG_ID, Priority=$PRIORITY, Project=$PROJECT"
}

# Обработка отчёта
process_report() {
  local report_file="$1"
  
  log_info "Обработка отчёта: $report_file"
  
  # Валидация
  if ! validate_report "$report_file"; then
    log_error "Отчёт не прошёл валидацию"
    mv "$report_file" "$FEEDBACK_DIR/errors/"
    return 1
  fi
  
  # Извлечь метаданные
  extract_metadata "$report_file"
  
  # Переместить в processed
  local project_prefix="${PROJECT//[^a-zA-Z0-9]/_}"
  local dest_file="$FEEDBACK_DIR/processed/${project_prefix}-${BUG_ID}.md"
  
  mv "$report_file" "$dest_file"
  
  log_success "Отчёт обработан и перемещён в $dest_file"
  
  # Обновить реестр
  update_registry "$PROJECT" "$BUG_ID" "$PRIORITY"
  
  return 0
}

# Обновление feedback-registry.json
update_registry() {
  local project="$1"
  local bug_id="$2"
  local priority="$3"
  
  log_info "Обновление feedback-registry.json..."
  
  if [ ! -f "$FEEDBACK_REGISTRY" ]; then
    echo '{"feedback": []}' > "$FEEDBACK_REGISTRY"
  fi
  
  # Создать временный файл
  local temp_file="${FEEDBACK_REGISTRY}.tmp"
  
  # Обновить реестр
  jq --arg proj "$project" \
     --arg id "$bug_id" \
     --arg priority "$priority" \
     --arg created "$(date -Iseconds)" \
     '.feedback += [{"project": $proj, "bug_id": $id, "priority": $priority, "status": "received", "created": $created}]' \
     "$FEEDBACK_REGISTRY" > "$temp_file"
  
  mv "$temp_file" "$FEEDBACK_REGISTRY"
  
  log_success "feedback-registry.json обновлён"
}

# Авто-обработка inbox
process_inbox() {
  log_info "Обработка inbox..."
  
  local inbox_dir="$FEEDBACK_DIR/inbox"
  local count=0
  
  for report_file in "$inbox_dir"/*.md; do
    if [ -f "$report_file" ]; then
      if process_report "$report_file"; then
        ((count++))
      fi
    fi
  done
  
  log_success "Обработано отчётов: $count"
}

# -----------------------------------------------------------------------------
# Основная функция
# -----------------------------------------------------------------------------

main() {
  echo -e "${BLUE}========================================${NC}"
  echo -e "${BLUE}  Приём отчётов о багах${NC}"
  echo -e "${BLUE}========================================${NC}"
  echo ""
  
  # Инициализация
  init_directories
  
  # Если передан файл — обработать его
  if [ -n "$1" ] && [ -f "$1" ]; then
    process_report "$1"
  else
    # Авто-обработка inbox
    process_inbox
  fi
  
  echo ""
  echo -e "${GREEN}✅ Приём отчётов завершён${NC}"
}

# Запуск
main "$@"
