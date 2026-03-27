#!/bin/bash

# =============================================================================
# receive-confirmation.sh - Приём подтверждений от ПРОЕКТОВ
# =============================================================================
# Назначение: Приём подтверждений о применении обновлений от ПРОЕКТОВ
# 
# Функционал:
#   - Приём подтверждений
#   - Валидация подтверждений
#   - Обновление feedback-registry.json
#   - Закрытие задач
#
# ВАЖНО: БЕЗ HARDCODE! Универсально для любого проекта.
#
# Использование:
#   .qwen/scripts/bug-tracking/receive-confirmation.sh [confirmation_file]
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
  mkdir -p "$FEEDBACK_DIR/confirmations"
  mkdir -p "$FEEDBACK_DIR/confirmations/processed"
}

# Валидация подтверждения
validate_confirmation() {
  local confirmation_file="$1"
  
  log_info "Валидация подтверждения..."
  
  # Проверить наличие обязательных полей
  local required_fields=("confirmation_id:" "project:" "status:" "applied_at:")
  
  for field in "${required_fields[@]}"; do
    if ! grep -q "^$field" "$confirmation_file"; then
      log_error "Отсутствует обязательное поле: $field"
      return 1
    fi
  done
  
  # Проверить статус
  local status=$(grep "^status:" "$confirmation_file" | cut -d':' -f2 | tr -d ' ')
  if [ "$status" != "applied" ]; then
    log_warning "Статус не 'applied': $status"
  fi
  
  log_success "Подтверждение валидно"
  return 0
}

# Извлечение метаданных
extract_metadata() {
  local confirmation_file="$1"
  
  CONFIRMATION_ID=$(grep "^confirmation_id:" "$confirmation_file" | cut -d':' -f2 | tr -d ' ')
  PROJECT=$(grep "^project:" "$confirmation_file" | cut -d':' -f2 | tr -d ' ')
  STATUS=$(grep "^status:" "$confirmation_file" | cut -d':' -f2 | tr -d ' ')
  APPLIED_AT=$(grep "^applied_at:" "$confirmation_file" | cut -d':' -f2 | tr -d ' ')
  UPDATES_COUNT=$(grep "^updates_applied:" "$confirmation_file" | cut -d':' -f2 | tr -d ' ' || echo "0")
  
  log_info "Метаданные: ConfirmationID=$CONFIRMATION_ID, Project=$PROJECT, Status=$STATUS"
}

# Обработка подтверждения
process_confirmation() {
  local confirmation_file="$1"
  
  log_info "Обработка подтверждения: $confirmation_file"
  
  # Валидация
  if ! validate_confirmation "$confirmation_file"; then
    log_error "Подтверждение не прошло валидацию"
    mv "$confirmation_file" "$FEEDBACK_DIR/confirmations/errors/"
    return 1
  fi
  
  # Извлечь метаданные
  extract_metadata "$confirmation_file"
  
  # Переместить в processed
  local project_prefix="${PROJECT//[^a-zA-Z0-9]/_}"
  local dest_file="$FEEDBACK_DIR/confirmations/processed/${project_prefix}-${CONFIRMATION_ID}.md"
  
  mv "$confirmation_file" "$dest_file"
  
  log_success "Подтверждение обработано и перемещено в $dest_file"
  
  # Обновить реестр
  update_registry "$PROJECT" "$CONFIRMATION_ID" "$STATUS"
  
  return 0
}

# Обновление feedback-registry.json
update_registry() {
  local project="$1"
  local confirmation_id="$2"
  local status="$3"
  
  log_info "Обновление feedback-registry.json..."
  
  if [ ! -f "$FEEDBACK_REGISTRY" ]; then
    echo '{"feedback": [], "confirmations": []}' > "$FEEDBACK_REGISTRY"
  fi
  
  # Создать временный файл
  local temp_file="${FEEDBACK_REGISTRY}.tmp"
  
  # Обновить реестр
  jq --arg proj "$project" \
     --arg id "$confirmation_id" \
     --arg status "$status" \
     --arg applied "$(date -Iseconds)" \
     '.confirmations += [{"project": $proj, "confirmation_id": $id, "status": $status, "applied_at": $applied}]' \
     "$FEEDBACK_REGISTRY" > "$temp_file"
  
  mv "$temp_file" "$FEEDBACK_REGISTRY"
  
  log_success "feedback-registry.json обновлён"
}

# Авто-обработка confirmations
process_confirmations() {
  log_info "Обработка подтверждений..."
  
  local inbox_dir="$FEEDBACK_DIR/confirmations"
  local count=0
  
  for confirmation_file in "$inbox_dir"/*.md; do
    if [ -f "$confirmation_file" ] && [[ ! "$confirmation_file" =~ /processed/ ]] && [[ ! "$confirmation_file" =~ /errors/ ]]; then
      if process_confirmation "$confirmation_file"; then
        ((count++))
      fi
    fi
  done
  
  log_success "Обработано подтверждений: $count"
}

# Закрытие задачи
close_task() {
  local project="$1"
  local confirmation_id="$2"
  
  log_info "Закрытие задачи для $project..."
  
  # Обновить task-registry.json
  if [ -f "$TASK_REGISTRY" ]; then
    local temp_file="${TASK_REGISTRY}.tmp"
    
    jq --arg proj "$project" \
       --arg id "$confirmation_id" \
       '.tasks = [.tasks[] | if .project == $proj and .confirmation_id == $id then .status = "closed" else . end]' \
       "$TASK_REGISTRY" > "$temp_file"
    
    mv "$temp_file" "$TASK_REGISTRY"
    
    log_success "Задача закрыта"
  fi
}

# -----------------------------------------------------------------------------
# Основная функция
# -----------------------------------------------------------------------------

main() {
  echo -e "${BLUE}========================================${NC}"
  echo -e "${BLUE}  Приём подтверждений${NC}"
  echo -e "${BLUE}========================================${NC}"
  echo ""
  
  # Инициализация
  init_directories
  
  mkdir -p "$FEEDBACK_DIR/confirmations/errors"
  
  # Если передан файл — обработать его
  if [ -n "$1" ] && [ -f "$1" ]; then
    process_confirmation "$1"
  else
    # Авто-обработка
    process_confirmations
  fi
  
  echo ""
  echo -e "${GREEN}✅ Приём подтверждений завершён${NC}"
}

# Запуск
main "$@"
