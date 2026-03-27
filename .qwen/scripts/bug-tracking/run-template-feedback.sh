#!/bin/bash

# =============================================================================
# run-template-feedback.sh - Запуск сбора обратной связи о ШАБЛОНЕ
# =============================================================================
# Назначение: Wrapper для запуска work_template_feedback агента
# 
# Функционал:
#   - Проверка зависимостей (Qwen Code CLI)
#   - Запуск агента work_template_feedback
#   - Обработка результатов
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

# Проверка Qwen Code CLI
check_qwen_cli() {
  log_info "Проверка Qwen Code CLI..."
  
  if ! command -v qwen &> /dev/null; then
    log_error "Qwen Code CLI не найден!"
    echo ""
    echo "Установка:"
    echo "  npm install -g @qwen-code/cli"
    echo ""
    echo "ИЛИ запуск через npx:"
    echo "  npx qwen --agent work_template_feedback"
    return 1
  fi
  
  log_success "Qwen Code CLI найден: $(qwen --version 2>&1 | head -1)"
}

# Проверка агента
check_agent() {
  log_info "Проверка агента work_template_feedback..."
  
  local agent_file="$SCRIPT_DIR/../../agents/work_template_feedback.md"
  
  if [ ! -f "$agent_file" ]; then
    log_error "Агент не найден: $agent_file"
    return 1
  fi
  
  log_success "Агент найден: $agent_file"
}

# Проверка зависимостей
check_dependencies() {
  log_info "Проверка зависимостей..."
  
  local deps_ok=true
  
  # Проверить скрипты
  if [ ! -f "$SCRIPT_DIR/template-feedback-report.sh" ]; then
    log_error "template-feedback-report.sh не найден"
    deps_ok=false
  fi
  
  if [ ! -f "$SCRIPT_DIR/send-template-feedback.sh" ]; then
    log_error "send-template-feedback.sh не найден"
    deps_ok=false
  fi
  
  # Проверить навыки
  if [ ! -f "$SCRIPT_DIR/../../skills/calculate-bug-priority/SKILL.md" ]; then
    log_error "calculate-bug-priority skill не найден"
    deps_ok=false
  fi
  
  if [ "$deps_ok" = true ]; then
    log_success "Все зависимости найдены"
  else
    return 1
  fi
}

# Запуск агента
run_agent() {
  log_info "Запуск work_template_feedback..."
  echo ""
  
  # Запустить Qwen Code с агентом
  qwen --agent work_template_feedback \
       --prompt "Запустить сбор обратной связи о ШАБЛОНЕ. Найти ошибки в компонентах ШАБЛОНА (.qwen/scripts, .qwen/agents, .qwen/skills, .qwen/templates). Игнорировать ошибки проекта."
  
  local exit_code=$?
  
  echo ""
  if [ $exit_code -eq 0 ]; then
    log_success "Агент завершён успешно"
  else
    log_error "Агент завершён с ошибкой: $exit_code"
  fi
  
  return $exit_code
}

# Проверка результатов
check_results() {
  log_info "Проверка результатов..."
  
  local bugs_dir="$SCRIPT_DIR/../../state/bugs"
  local registry_file="$SCRIPT_DIR/../../state/template-feedback-registry.json"
  
  # Проверить созданные отчёты
  if [ -d "$bugs_dir" ]; then
    local report_count=$(ls -1 "$bugs_dir"/*.md 2>/dev/null | wc -l || echo "0")
    
    if [ "$report_count" -gt 0 ]; then
      log_success "Создано отчётов: $report_count"
      echo ""
      echo "Последние отчёты:"
      ls -lt "$bugs_dir"/*.md 2>/dev/null | head -5
    else
      log_info "Отчёты не созданы (ошибки ШАБЛОНА не найдены)"
    fi
  fi
  
  # Проверить реестр
  if [ -f "$registry_file" ]; then
    log_success "Реестр обновлён: $registry_file"
  fi
}

# Вывод помощи
show_help() {
  echo -e "${BLUE}========================================${NC}"
  echo -e "${BLUE}  Сбор обратной связи о ШАБЛОНЕ${NC}"
  echo -e "${BLUE}========================================${NC}"
  echo ""
  echo "Использование:"
  echo "  $0"
  echo ""
  echo "Описание:"
  echo "  Запускает work_template_feedback агент для сбора"
  echo "  обратной связи о ШАБЛОНЕ (qwen_orc_kit_ru)."
  echo ""
  echo "  Собирает ТОЛЬКО ошибки в ШАБЛОНЕ:"
  echo "    - .qwen/scripts/ - скрипты ШАБЛОНА"
  echo "    - .qwen/agents/ - агенты ШАБЛОНА"
  echo "    - .qwen/skills/ - навыки ШАБЛОНА"
  echo "    - .qwen/templates/ - шаблоны ШАБЛОНА"
  echo ""
  echo "  Игнорирует:"
  echo "    - Ошибки проекта"
  echo "    - Падающие тесты проекта"
  echo ""
  echo "Зависимости:"
  echo "  - Qwen Code CLI"
  echo "  - work_template_feedback агент"
  echo "  - template-feedback-report.sh"
  echo "  - send-template-feedback.sh"
  echo ""
  echo "Примеры:"
  echo "  # Запустить сбор обратной связи"
  echo "  $0"
  echo ""
  echo "  # Через Qwen Code напрямую"
  echo "  qwen --agent work_template_feedback"
  echo ""
}

# -----------------------------------------------------------------------------
# Основная функция
# -----------------------------------------------------------------------------

main() {
  echo -e "${BLUE}========================================${NC}"
  echo -e "${BLUE}  Сбор обратной связи о ШАБЛОНЕ${NC}"
  echo -e "${BLUE}========================================${NC}"
  echo ""
  
  # Проверка флагов
  if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    show_help
    exit 0
  fi
  
  # Проверки
  check_qwen_cli || exit 1
  check_agent || exit 1
  check_dependencies || exit 1
  
  echo ""
  
  # Запуск агента
  run_agent
  local exit_code=$?
  
  echo ""
  
  # Проверка результатов
  check_results
  
  echo ""
  if [ $exit_code -eq 0 ]; then
    echo -e "${GREEN}✅ Сбор обратной связи завершён${NC}"
  else
    echo -e "${RED}❌ Сбор обратной связи завершён с ошибкой${NC}"
  fi
  
  return $exit_code
}

# Запуск
main "$@"
