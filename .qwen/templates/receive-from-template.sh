#!/bin/bash

# =============================================================================
# receive-from-template.sh - Приём обновлений из ШАБЛОНА
# =============================================================================
# Назначение: Приём обновлений из ШАБЛОНА и подготовка к применению
# 
# Функционал:
#   - Проверка директории updates
#   - Валидация обновлений
#   - Уведомление о новых обновлениях
#
# ВАЖНО: БЕЗ HARDCODE! Универсально для любого проекта.
#
# Использование:
#   .qwen/scripts/template/receive-from-template.sh
# =============================================================================

set -e

# -----------------------------------------------------------------------------
# Инициализация
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Загрузить конфигурацию ПРОЕКТА
if [ -f "$SCRIPT_DIR/../../config.sh" ]; then
  source "$SCRIPT_DIR/../../config.sh"
else
  # Конфигурация по умолчанию
  PROJECT_NAME="${PROJECT_NAME:-my-project}"
  PROJECT_ROOT="${PROJECT_ROOT:-$(pwd)}"
  TEMPLATE_ROOT="${TEMPLATE_ROOT:-$PROJECT_ROOT/.qwen/template}"
fi

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
  mkdir -p "$PROJECT_ROOT/.qwen/template/updates"
  mkdir -p "$PROJECT_ROOT/.qwen/template/applied"
  mkdir -p "$PROJECT_ROOT/.qwen/template/confirmations"
}

# Проверка обновлений
check_updates() {
  log_info "Проверка обновлений..."
  
  local updates_dir="$PROJECT_ROOT/.qwen/template/updates"
  local count=0
  
  if [ -d "$updates_dir" ]; then
    count=$(ls -1 "$updates_dir"/*.md 2>/dev/null | wc -l || echo "0")
  fi
  
  if [ "$count" -gt 0 ]; then
    log_success "Найдено обновлений: $count"
  else
    log_info "Обновлений не найдено"
  fi
  
  echo "$count"
}

# Валидация обновления
validate_update() {
  local update_file="$1"
  
  log_info "Валидация обновления: $(basename "$update_file")"
  
  # Проверить наличие обязательных полей
  local required_fields=("update_type:" "update_id:" "created:")
  
  for field in "${required_fields[@]}"; do
    if ! grep -q "^$field" "$update_file"; then
      log_error "Отсутствует обязательное поле: $field"
      return 1
    fi
  done
  
  log_success "Обновление валидно"
  return 0
}

# Обработка обновлений
process_updates() {
  log_info "Обработка обновлений..."
  
  local updates_dir="$PROJECT_ROOT/.qwen/template/updates"
  local valid_count=0
  local invalid_count=0
  
  for update_file in "$updates_dir"/*.md; do
    if [ -f "$update_file" ]; then
      if validate_update "$update_file"; then
        ((valid_count++))
      else
        ((invalid_count++))
        # Переместить в errors
        mkdir -p "$PROJECT_ROOT/.qwen/template/errors"
        mv "$update_file" "$PROJECT_ROOT/.qwen/template/errors/"
      fi
    fi
  done
  
  log_success "Обработано: $valid_count валидных, $invalid_count невалидных"
  
  return $invalid_count
}

# Уведомление о новых обновлениях
notify_updates() {
  local count="$1"
  
  if [ "$count" -gt 0 ]; then
    log_info "Создание уведомления о новых обновлениях..."
    
    local notification_file="$PROJECT_ROOT/.qwen/template/notifications/updates-available-$(date +%Y%m%d-%H%M%S).md"
    
    mkdir -p "$(dirname "$notification_file")"
    
    cat > "$notification_file" << EOF
---
notification_id: updates-available-$(date +%Y%m%d-%H%M%S)
project: $PROJECT_NAME
type: updates_available
count: $count
created_at: $(date -Iseconds)
---

# Notification: Updates Available

## Project
- Name: $PROJECT_NAME
- Type: ${PROJECT_TYPE:-unknown}

## Updates
- Count: $count
- Location: $PROJECT_ROOT/.qwen/template/updates/

## Action Required
Запустите apply-template-update.sh для применения обновлений

## Timestamp
$created_at
EOF
    
    log_success "Уведомление создано: $notification_file"
  fi
}

# -----------------------------------------------------------------------------
# Основная функция
# -----------------------------------------------------------------------------

main() {
  echo -e "${BLUE}========================================${NC}"
  echo -e "${BLUE}  Приём обновлений из ШАБЛОНА${NC}"
  echo -e "${BLUE}========================================${NC}"
  echo ""
  
  # Инициализация
  init_directories
  
  # Проверка
  local count=$(check_updates)
  
  # Обработка
  if [ "$count" -gt 0 ]; then
    process_updates
    notify_updates "$count"
  fi
  
  echo ""
  if [ "$count" -gt 0 ]; then
    echo -e "${GREEN}✅ Обновления получены: $count${NC}"
    echo ""
    echo "Запустите: .qwen/scripts/template/apply-template-update.sh"
  else
    echo -e "${BLUE}ℹ️  Обновлений нет${NC}"
  fi
}

# Запуск
main "$@"
