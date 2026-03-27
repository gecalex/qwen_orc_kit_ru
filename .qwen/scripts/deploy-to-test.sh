#!/bin/bash

# =============================================================================
# deploy-to-test.sh - Копирование изменений в тестовый проект
# =============================================================================
# Назначение: Автоматическое копирование изменённых файлов из ШАБЛОНА в ПРОЕКТ
# 
# Функционал:
#   - Определение изменённых файлов
#   - Копирование в тестовый проект
#   - Проверка копирования
#
# Использование:
#   .qwen/scripts/deploy-to-test.sh [test_project_path]
# =============================================================================

set -e

# -----------------------------------------------------------------------------
# Инициализация
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_ROOT="$SCRIPT_DIR/../.."

# Тестовый проект (по умолчанию PKB_test)
TEST_PROJECT="${1:-/home/alex/MyProjects/PKB_test}"

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

# Проверка наличия тестового проекта
check_test_project() {
  if [ ! -d "$TEST_PROJECT" ]; then
    log_error "Тестовый проект не найден: $TEST_PROJECT"
    exit 1
  fi
  
  if [ ! -d "$TEST_PROJECT/.qwen" ]; then
    log_error ".qwen директория не найдена в тестовом проекте"
    exit 1
  fi
  
  log_success "Тестовый проект найден: $TEST_PROJECT"
}

# Копирование конфигурации
copy_config() {
  log_info "Копирование конфигурации..."
  
  if [ -f "$TEMPLATE_ROOT/.qwen/config.sh" ]; then
    cp "$TEMPLATE_ROOT/.qwen/config.sh" "$TEST_PROJECT/.qwen/"
    log_success "config.sh скопирован"
  else
    log_warning "config.sh не найден в ШАБЛОНЕ"
  fi
}

# Копирование агентов
copy_agents() {
  log_info "Копирование агентов..."
  
  local agents=("work_template_feedback.md" "orc_bug_auto_fixer.md")
  
  for agent in "${agents[@]}"; do
    if [ -f "$TEMPLATE_ROOT/.qwen/agents/$agent" ]; then
      cp "$TEMPLATE_ROOT/.qwen/agents/$agent" "$TEST_PROJECT/.qwen/agents/"
      log_success "Агент скопирован: $agent"
    else
      log_warning "Агент не найден: $agent"
    fi
  done
}

# Копирование скриптов
copy_scripts() {
  log_info "Копирование скриптов..."
  
  if [ -d "$TEMPLATE_ROOT/.qwen/scripts/bug-tracking" ]; then
    mkdir -p "$TEST_PROJECT/.qwen/scripts/bug-tracking"
    cp -r "$TEMPLATE_ROOT/.qwen/scripts/bug-tracking/"* "$TEST_PROJECT/.qwen/scripts/bug-tracking/"
    log_success "Скрипты bug-tracking скопированы"
  else
    log_warning "bug-tracking скрипты не найдены"
  fi
  
  if [ -d "$TEMPLATE_ROOT/.qwen/scripts/template" ]; then
    mkdir -p "$TEST_PROJECT/.qwen/scripts/template"
    cp -r "$TEMPLATE_ROOT/.qwen/scripts/template/"* "$TEST_PROJECT/.qwen/scripts/template/"
    log_success "Скрипты template скопированы"
  else
    log_warning "template скрипты не найдены"
  fi
}

# Копирование навыков
copy_skills() {
  log_info "Копирование навыков..."
  
  if [ -d "$TEMPLATE_ROOT/.qwen/skills/calculate-bug-priority" ]; then
    mkdir -p "$TEST_PROJECT/.qwen/skills/calculate-bug-priority"
    cp -r "$TEMPLATE_ROOT/.qwen/skills/calculate-bug-priority/"* "$TEST_PROJECT/.qwen/skills/calculate-bug-priority/"
    log_success "Навык calculate-bug-priority скопирован"
  else
    log_warning "Навык calculate-bug-priority не найден"
  fi
}

# Копирование шаблонов
copy_templates() {
  log_info "Копирование шаблонов..."
  
  if [ -d "$TEMPLATE_ROOT/.qwen/templates" ]; then
    # Копировать только шаблоны для проектов
    local project_templates=("project-config.sh" "apply-template-update.sh" "send-confirmation.sh" "receive-from-template.sh")
    
    for template in "${project_templates[@]}"; do
      if [ -f "$TEMPLATE_ROOT/.qwen/templates/$template" ]; then
        cp "$TEMPLATE_ROOT/.qwen/templates/$template" "$TEST_PROJECT/.qwen/"
        log_success "Шаблон скопирован: $template"
      fi
    done
  else
    log_warning "templates директория не найдена"
  fi
}

# Проверка копирования
verify_copy() {
  log_info "Проверка копирования..."
  
  local errors=0
  
  # Проверить конфигурацию
  if [ ! -f "$TEST_PROJECT/.qwen/config.sh" ]; then
    log_error "config.sh не скопирован"
    ((errors++))
  fi
  
  # Проверить агентов
  if [ ! -f "$TEST_PROJECT/.qwen/agents/work_template_feedback.md" ]; then
    log_error "work_template_feedback.md не скопирован"
    ((errors++))
  fi
  
  # Проверить скрипты
  if [ ! -d "$TEST_PROJECT/.qwen/scripts/bug-tracking" ]; then
    log_error "bug-tracking скрипты не скопированы"
    ((errors++))
  fi
  
  # Проверить навыки
  if [ ! -d "$TEST_PROJECT/.qwen/skills/calculate-bug-priority" ]; then
    log_error "calculate-bug-priority не скопирован"
    ((errors++))
  fi
  
  if [ "$errors" -eq 0 ]; then
    log_success "Все файлы скопированы успешно"
  else
    log_error "Ошибок при копировании: $errors"
  fi
  
  return $errors
}

# -----------------------------------------------------------------------------
# Основная функция
# -----------------------------------------------------------------------------

main() {
  echo -e "${BLUE}========================================${NC}"
  echo -e "${BLUE}  Копирование в тестовый проект${NC}"
  echo -e "${BLUE}========================================${NC}"
  echo ""
  
  # Проверки
  check_test_project
  
  # Копирование
  copy_config
  copy_agents
  copy_scripts
  copy_skills
  copy_templates
  
  # Проверка
  if verify_copy; then
    echo ""
    echo -e "${GREEN}✅ Копирование завершено успешно${NC}"
    echo ""
    echo "Тестовый проект: $TEST_PROJECT"
    echo ""
    echo "Следующий шаг:"
    echo "  cd $TEST_PROJECT"
    echo "  git checkout -b test/bug-tracking-system-v2"
    echo "  "
    echo "  # Запуск через оркестратора:"
    echo "  task '{"
    echo "    \"subagent_type\": \"work_template_feedback\","
    echo "    \"prompt\": \"Запустить сбор обратной связи о ШАБЛОНЕ\""
    echo "  }'"
  else
    echo ""
    echo -e "${RED}❌ Копирование завершено с ошибками${NC}"
    exit 1
  fi
}

# Запуск
main "$@"
