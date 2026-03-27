#!/bin/bash

# =============================================================================
# apply-template-update.sh - Применение обновлений из ШАБЛОНА
# =============================================================================
# Назначение: Применение обновлений ШАБЛОНА в ПРОЕКТЕ
# 
# Функционал:
#   - Получение обновлений из ШАБЛОНА
#   - Валидация обновлений
#   - Применение обновлений
#   - Проверка Quality Gate
#   - Отправка подтверждения
#
# ВАЖНО: БЕЗ HARDCODE! Универсально для любого проекта.
#
# Использование:
#   .qwen/scripts/template/apply-template-update.sh [update_file|all]
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
  mkdir -p "$PROJECT_ROOT/.qwen/template/errors"
}

# Валидация обновления
validate_update() {
  local update_file="$1"
  
  log_info "Валидация обновления..."
  
  # Проверить наличие файла
  if [ ! -f "$update_file" ]; then
    log_error "Файл обновления не найден: $update_file"
    return 1
  fi
  
  # Проверить тип обновления
  local update_type=$(grep "^update_type:" "$update_file" 2>/dev/null | cut -d':' -f2 | tr -d ' ' || echo "unknown")
  
  case "$update_type" in
    agent|skill|script|config|all)
      log_success "Тип обновления: $update_type"
      ;;
    *)
      log_warning "Неизвестный тип обновления: $update_type"
      ;;
  esac
  
  return 0
}

# Применение обновления (агент)
apply_agent_update() {
  local update_file="$1"
  
  log_info "Применение обновления агента..."
  
  # Извлечь имя агента
  local agent_name=$(grep "^agent_name:" "$update_file" | cut -d':' -f2 | tr -d ' ')
  
  if [ -z "$agent_name" ]; then
    log_error "Имя агента не найдено"
    return 1
  fi
  
  # Извлечь содержимое
  local content=$(sed -n '/^---content---$/,$ p' "$update_file" | tail -n +2)
  
  # Сохранить агента
  echo "$content" > "$PROJECT_ROOT/.qwen/agents/${agent_name}.md"
  
  log_success "Агент обновлён: $agent_name"
  return 0
}

# Применение обновления (скрипт)
apply_script_update() {
  local update_file="$1"
  
  log_info "Применение обновления скрипта..."
  
  # Извлечь имя скрипта
  local script_name=$(grep "^script_name:" "$update_file" | cut -d':' -f2 | tr -d ' ')
  local script_path=$(grep "^script_path:" "$update_file" | cut -d':' -f2 | tr -d ' ')
  
  if [ -z "$script_name" ]; then
    log_error "Имя скрипта не найдено"
    return 1
  fi
  
  # Извлечь содержимое
  local content=$(sed -n '/^---content---$/,$ p' "$update_file" | tail -n +2)
  
  # Создать директорию
  local script_dir=$(dirname "$PROJECT_ROOT/$script_path")
  mkdir -p "$script_dir"
  
  # Сохранить скрипт
  echo "$content" > "$PROJECT_ROOT/$script_path"
  chmod +x "$PROJECT_ROOT/$script_path"
  
  log_success "Скрипт обновлён: $script_name"
  return 0
}

# Применение обновления (конфигурация)
apply_config_update() {
  local update_file="$1"
  
  log_info "Применение обновления конфигурации..."
  
  # Извлечь содержимое
  local content=$(sed -n '/^---content---$/,$ p' "$update_file" | tail -n +2)
  
  # Сохранить конфигурацию
  echo "$content" > "$PROJECT_ROOT/.qwen/config.sh"
  
  log_success "Конфигурация обновлена"
  return 0
}

# Применение всех обновлений
apply_all_updates() {
  log_info "Применение всех обновлений..."
  
  local updates_dir="$PROJECT_ROOT/.qwen/template/updates"
  local count=0
  local failed=0
  
  for update_file in "$updates_dir"/*.md; do
    if [ -f "$update_file" ]; then
      if apply_update "$update_file"; then
        ((count++))
      else
        ((failed++))
      fi
    fi
  done
  
  log_success "Применено обновлений: $count, Неудач: $failed"
  
  return $failed
}

# Универсальное применение обновления
apply_update() {
  local update_file="$1"
  
  log_info "Применение обновления: $update_file"
  
  # Валидация
  if ! validate_update "$update_file"; then
    log_error "Обновление не прошло валидацию"
    mv "$update_file" "$PROJECT_ROOT/.qwen/template/errors/"
    return 1
  fi
  
  # Извлечь тип обновления
  local update_type=$(grep "^update_type:" "$update_file" | cut -d':' -f2 | tr -d ' ' || echo "unknown")
  
  # Применить по типу
  case "$update_type" in
    agent)
      apply_agent_update "$update_file"
      ;;
    script)
      apply_script_update "$update_file"
      ;;
    config)
      apply_config_update "$update_file"
      ;;
    all)
      apply_all_updates
      ;;
    *)
      log_warning "Неизвестный тип обновления: $update_type"
      ;;
  esac
  
  # Переместить в applied
  mv "$update_file" "$PROJECT_ROOT/.qwen/template/applied/"
  
  log_success "Обновление применено"
  return 0
}

# Quality Gate
run_quality_gate() {
  log_info "Запуск Quality Gate..."
  
  if [ -f "$PROJECT_ROOT/.qwen/scripts/quality-gates/check-tests.sh" ]; then
    "$PROJECT_ROOT/.qwen/scripts/quality-gates/check-tests.sh"
    log_success "Quality Gate пройден"
  else
    log_warning "check-tests.sh не найден, пропускаем Quality Gate"
  fi
  
  return 0
}

# Отправка подтверждения
send_confirmation() {
  log_info "Отправка подтверждения..."
  
  if [ -f "$SCRIPT_DIR/send-confirmation.sh" ]; then
    "$SCRIPT_DIR/send-confirmation.sh"
    log_success "Подтверждение отправлено"
  else
    log_warning "send-confirmation.sh не найден"
  fi
}

# -----------------------------------------------------------------------------
# Основная функция
# -----------------------------------------------------------------------------

main() {
  echo -e "${BLUE}========================================${NC}"
  echo -e "${BLUE}  Применение обновлений ШАБЛОНА${NC}"
  echo -e "${BLUE}========================================${NC}"
  echo ""
  
  # Инициализация
  init_directories
  
  # Если передан файл — обработать его
  if [ -n "$1" ] && [ "$1" != "all" ]; then
    apply_update "$1"
  else
    # Применить все обновления
    apply_all_updates
  fi
  
  # Quality Gate
  run_quality_gate
  
  # Отправка подтверждения
  send_confirmation
  
  echo ""
  echo -e "${GREEN}✅ Обновления применены${NC}"
}

# Запуск
main "$@"
