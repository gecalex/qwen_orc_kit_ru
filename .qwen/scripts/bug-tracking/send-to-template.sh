#!/bin/bash

# =============================================================================
# send-to-template.sh - Отправка отчёта о баге в ШАБЛОН
# =============================================================================
# Назначение: Отправка отчёта о баге из ПРОЕКТА в ШАБЛОН для исправления
# 
# Функционал:
#   - Копирование отчёта в директорию ШАБЛОНА
#   - Поддержка различных транспортов (git, http, rsync)
#   - Универсальность (БЕЗ HARDCODE имён проектов)
#
# ВАЖНО: БЕЗ HARDCODE! Универсально для любого проекта.
#
# Использование:
#   .qwen/scripts/bug-tracking/send-to-template.sh <report_file>
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

# Проверка входных данных
check_input() {
  local report_file="$1"
  
  if [ -z "$report_file" ]; then
    log_error "Usage: $0 <report_file>"
    exit 1
  fi
  
  if [ ! -f "$report_file" ]; then
    log_error "Файл отчёта не найден: $report_file"
    exit 1
  fi
  
  log_success "Файл отчёта найден: $report_file"
}

# Отправка через git
send_via_git() {
  local report_file="$1"
  local inbox_dir="$TEMPLATE_ROOT/.qwen/state/feedback/inbox"
  
  log_info "Отправка через git..."
  
  # Создать директорию inbox
  mkdir -p "$inbox_dir"
  
  # Извлечь bug_id из отчёта
  local bug_id=$(grep "^bug_id:" "$report_file" | cut -d':' -f2 | tr -d ' ')
  
  # Копировать с новым именем (чтобы избежать конфликтов)
  local project_prefix="${PROJECT_NAME//[^a-zA-Z0-9]/_}"
  local dest_file="$inbox_dir/${project_prefix}-${bug_id}.md"
  
  cp "$report_file" "$dest_file"
  
  log_success "Отчёт скопирован в $dest_file"
}

# Отправка через HTTP
send_via_http() {
  local report_file="$1"
  
  log_info "Отправка через HTTP..."
  
  if [ -z "$TEMPLATE_WEBHOOK" ]; then
    log_warning "TEMPLATE_WEBHOOK не настроен, используем git"
    send_via_git "$report_file"
    return
  fi
  
  # HTTP POST
  curl -X POST "$TEMPLATE_WEBHOOK" \
    -F "project=$PROJECT_NAME" \
    -F "report=@$report_file" \
    -H "Accept: application/json"
  
  log_success "Отчёт отправлен через HTTP"
}

# Отправка через rsync
send_via_rsync() {
  local report_file="$1"
  local inbox_dir="$TEMPLATE_ROOT/.qwen/state/feedback/inbox"
  
  log_info "Отправка через rsync..."
  
  # Создать директорию inbox
  mkdir -p "$inbox_dir"
  
  # Копировать через rsync
  rsync -av "$report_file" "$inbox_dir/"
  
  log_success "Отчёт отправлен через rsync"
}

# Универсальная отправка
send_report() {
  local report_file="$1"
  
  case "$TRANSPORT_METHOD" in
    git)
      send_via_git "$report_file"
      ;;
    http)
      send_via_http "$report_file"
      ;;
    rsync)
      send_via_rsync "$report_file"
      ;;
    *)
      log_warning "Неизвестный транспорт: $TRANSPORT_METHOD, используем git"
      send_via_git "$report_file"
      ;;
  esac
}

# -----------------------------------------------------------------------------
# Основная функция
# -----------------------------------------------------------------------------

main() {
  echo -e "${BLUE}========================================${NC}"
  echo -e "${BLUE}  Отправка отчёта в ШАБЛОН${NC}"
  echo -e "${BLUE}========================================${NC}"
  echo ""
  
  # Проверка
  check_input "$1"
  
  # Отправка
  send_report "$1"
  
  echo ""
  echo -e "${GREEN}✅ Отчёт отправлен в ШАБЛОН${NC}"
  echo ""
  echo "Project: $PROJECT_NAME"
  echo "Transport: $TRANSPORT_METHOD"
}

# Запуск
main "$@"
