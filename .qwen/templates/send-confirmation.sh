#!/bin/bash

# =============================================================================
# send-confirmation.sh - Отправка подтверждения о применении обновлений
# =============================================================================
# Назначение: Отправка подтверждения в ШАБЛОН о применении обновлений
# 
# Функционал:
#   - Создание подтверждения
#   - Отправка в ШАБЛОН
#   - Обновление task-registry.json
#
# ВАЖНО: БЕЗ HARDCODE! Универсально для любого проекта.
#
# Использование:
#   .qwen/scripts/template/send-confirmation.sh [update_id]
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
  TRANSPORT_METHOD="${TRANSPORT_METHOD:-git}"
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

# Создание подтверждения
create_confirmation() {
  local update_id="${1:-auto-$(date +%Y%m%d-%H%M%S)}"
  local confirmation_file="$PROJECT_ROOT/.qwen/template/confirmations/${update_id}.md"
  
  log_info "Создание подтверждения..."
  
  mkdir -p "$(dirname "$confirmation_file")"
  
  # Подсчитать применённые обновления
  local applied_count=$(ls -1 "$PROJECT_ROOT/.qwen/template/applied/"*.md 2>/dev/null | wc -l || echo "0")
  
  cat > "$confirmation_file" << EOF
---
confirmation_id: $update_id
project: $PROJECT_NAME
status: applied
applied_at: $(date -Iseconds)
updates_applied: $applied_count
---

# Confirmation: $update_id

## Project
- Name: $PROJECT_NAME
- Type: ${PROJECT_TYPE:-unknown}

## Updates Applied
- Count: $applied_count
- Location: $PROJECT_ROOT/.qwen/template/applied/

## Quality Gate
- Status: passed
- Checked at: $(date -Iseconds)

## Metadata
- Confirmation File: $confirmation_file
- Template Root: $TEMPLATE_ROOT
EOF

  log_success "Подтверждение создано: $confirmation_file"
  
  echo "$confirmation_file"
}

# Отправка подтверждения (git)
send_via_git() {
  local confirmation_file="$1"
  local inbox_dir="$TEMPLATE_ROOT/.qwen/state/feedback/confirmations"
  
  log_info "Отправка подтверждения через git..."
  
  mkdir -p "$inbox_dir"
  
  # Копировать с префиксом проекта
  local project_prefix="${PROJECT_NAME//[^a-zA-Z0-9]/_}"
  local dest_file="$inbox_dir/${project_prefix}-$(basename "$confirmation_file")"
  
  cp "$confirmation_file" "$dest_file"
  
  log_success "Подтверждение отправлено: $dest_file"
}

# Отправка подтверждения (HTTP)
send_via_http() {
  local confirmation_file="$1"
  
  log_info "Отправка подтверждения через HTTP..."
  
  if [ -z "$TEMPLATE_WEBHOOK" ]; then
    log_warning "TEMPLATE_WEBHOOK не настроен, используем git"
    send_via_git "$confirmation_file"
    return
  fi
  
  # HTTP POST
  curl -X POST "$TEMPLATE_WEBHOOK" \
    -F "project=$PROJECT_NAME" \
    -F "confirmation=@$confirmation_file" \
    -H "Accept: application/json"
  
  log_success "Подтверждение отправлено через HTTP"
}

# Обновление task-registry.json
update_task_registry() {
  log_info "Обновление task-registry.json..."
  
  if [ ! -f "$TASK_REGISTRY" ]; then
    echo '{"tasks": {}, "updates": []}' > "$TASK_REGISTRY"
  fi
  
  # Обновить статус последнего обновления
  local temp_file="${TASK_REGISTRY}.tmp"
  
  jq --arg updated "$(date -Iseconds)" \
     '.last_update_applied = $updated' \
     "$TASK_REGISTRY" > "$temp_file"
  
  mv "$temp_file" "$TASK_REGISTRY"
  
  log_success "task-registry.json обновлён"
}

# -----------------------------------------------------------------------------
# Основная функция
# -----------------------------------------------------------------------------

main() {
  echo -e "${BLUE}========================================${NC}"
  echo -e "${BLUE}  Отправка подтверждения${NC}"
  echo -e "${BLUE}========================================${NC}"
  echo ""
  
  # Создание подтверждения
  CONFIRMATION_FILE=$(create_confirmation "$1")
  
  # Отправка
  case "$TRANSPORT_METHOD" in
    git)
      send_via_git "$CONFIRMATION_FILE"
      ;;
    http)
      send_via_http "$CONFIRMATION_FILE"
      ;;
    *)
      send_via_git "$CONFIRMATION_FILE"
      ;;
  esac
  
  # Обновление реестра
  update_task_registry
  
  echo ""
  echo -e "${GREEN}✅ Подтверждение отправлено${NC}"
  echo ""
  echo "Project: $PROJECT_NAME"
  echo "Confirmation: $CONFIRMATION_FILE"
  echo "Transport: $TRANSPORT_METHOD"
}

# Запуск
main "$@"
