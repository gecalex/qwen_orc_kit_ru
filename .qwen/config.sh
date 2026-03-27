#!/bin/bash

# =============================================================================
# .qwen/config.sh - Конфигурация ШАБЛОНА
# =============================================================================
# Назначение: Универсальная конфигурация для ШАБЛОНА qwen_orc_kit_ru
# 
# ВАЖНО: БЕЗ HARDCODE! Все значения настраиваемые.
# 
# Использование:
#   source .qwen/config.sh
# =============================================================================

set -e

# -----------------------------------------------------------------------------
# Основные настройки
# -----------------------------------------------------------------------------

TEMPLATE_NAME="${TEMPLATE_NAME:-qwen_orc_kit_ru}"
TEMPLATE_VERSION="${TEMPLATE_VERSION:-0.7.0}"
TEMPLATE_ROOT="${TEMPLATE_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"

# -----------------------------------------------------------------------------
# Директории
# -----------------------------------------------------------------------------

# Состояние
STATE_DIR="${STATE_DIR:-$TEMPLATE_ROOT/.qwen/state}"
BUGS_DIR="${BUGS_DIR:-$STATE_DIR/bugs}"
FEEDBACK_DIR="${FEEDBACK_DIR:-$STATE_DIR/feedback}"
TASKS_DIR="${TASKS_DIR:-$STATE_DIR/tasks}"

# Скрипты
SCRIPTS_DIR="${SCRIPTS_DIR:-$TEMPLATE_ROOT/.qwen/scripts}"
BUG_TRACKING_SCRIPTS="${BUG_TRACKING_SCRIPTS:-$SCRIPTS_DIR/bug-tracking}"
QUALITY_GATES_SCRIPTS="${QUALITY_GATES_SCRIPTS:-$SCRIPTS_DIR/quality-gates}"
GIT_SCRIPTS="${GIT_SCRIPTS:-$SCRIPTS_DIR/git}"

# Агенты
AGENTS_DIR="${AGENTS_DIR:-$TEMPLATE_ROOT/.qwen/agents}"
SKILLS_DIR="${SKILLS_DIR:-$TEMPLATE_ROOT/.qwen/skills}"

# -----------------------------------------------------------------------------
# Реестры
# -----------------------------------------------------------------------------

BUG_REGISTRY="${BUG_REGISTRY:-$STATE_DIR/bug-registry.json}"
FEEDBACK_REGISTRY="${FEEDBACK_REGISTRY:-$STATE_DIR/feedback-registry.json}"
TASK_REGISTRY="${TASK_REGISTRY:-$STATE_DIR/task-registry.json}"

# -----------------------------------------------------------------------------
# Транспорт
# -----------------------------------------------------------------------------

TRANSPORT_METHOD="${TRANSPORT_METHOD:-git}"
TEMPLATE_WEBHOOK="${TEMPLATE_WEBHOOK:-}"

# -----------------------------------------------------------------------------
# SLA (в минутах)
# -----------------------------------------------------------------------------

SLA_P0_CRITICAL="${SLA_P0_CRITICAL:-60}"      # 1 час
SLA_P1_HIGH="${SLA_P1_HIGH:-240}"              # 4 часа
SLA_P2_MEDIUM="${SLA_P2_MEDIUM:-1440}"         # 24 часа
SLA_P3_LOW="${SLA_P3_LOW:-10080}"              # 7 дней

# -----------------------------------------------------------------------------
# Quality Gates
# -----------------------------------------------------------------------------

MAX_WARNINGS="${MAX_WARNINGS:-50}"
MAX_FAILED="${MAX_FAILED:-0}"
MAX_ERRORS="${MAX_ERRORS:-0}"

# -----------------------------------------------------------------------------
# Функции
# -----------------------------------------------------------------------------

# Инициализация директорий
init_directories() {
  mkdir -p "$STATE_DIR" "$BUGS_DIR" "$FEEDBACK_DIR" "$TASKS_DIR"
  mkdir -p "$BUG_TRACKING_SCRIPTS" "$QUALITY_GATES_SCRIPTS" "$GIT_SCRIPTS"
}

# Проверка конфигурации
check_config() {
  if [ ! -d "$TEMPLATE_ROOT" ]; then
    echo "❌ TEMPLATE_ROOT не существует: $TEMPLATE_ROOT"
    return 1
  fi
  
  if [ ! -f "$TEMPLATE_ROOT/.qwen/settings.json" ]; then
    echo "⚠️  .qwen/settings.json не найден"
  fi
  
  return 0
}

# Логирование
log_info() {
  echo -e "\033[0;34m[INFO]\033[0m $1"
}

log_success() {
  echo -e "\033[0;32m[OK]\033[0m $1"
}

log_warning() {
  echo -e "\033[1;33m[WARN]\033[0m $1"
}

log_error() {
  echo -e "\033[0;31m[ERROR]\033[0m $1"
}

# -----------------------------------------------------------------------------
# Инициализация
# -----------------------------------------------------------------------------

init_directories
check_config || true

# Экспорт переменных
export TEMPLATE_NAME TEMPLATE_VERSION TEMPLATE_ROOT
export STATE_DIR BUGS_DIR FEEDBACK_DIR TASKS_DIR
export SCRIPTS_DIR BUG_TRACKING_SCRIPTS QUALITY_GATES_SCRIPTS GIT_SCRIPTS
export AGENTS_DIR SKILLS_DIR
export BUG_REGISTRY FEEDBACK_REGISTRY TASK_REGISTRY
export TRANSPORT_METHOD TEMPLATE_WEBHOOK
export SLA_P0_CRITICAL SLA_P1_HIGH SLA_P2_MEDIUM SLA_P3_LOW
export MAX_WARNINGS MAX_FAILED MAX_ERRORS
