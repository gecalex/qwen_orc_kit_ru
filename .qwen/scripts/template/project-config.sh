#!/bin/bash

# =============================================================================
# .qwen/config.sh - Конфигурация ПРОЕКТА (шаблон)
# =============================================================================
# Назначение: Универсальная конфигурация для ПРОЕКТОВ, использующих ШАБЛОН
# 
# ВАЖНО: БЕЗ HARDCODE! Все значения настраиваемые.
# Этот файл копируется в каждый проект при инициализации.
# 
# Использование:
#   source .qwen/config.sh
# =============================================================================

set -e

# -----------------------------------------------------------------------------
# Основные настройки
# -----------------------------------------------------------------------------

PROJECT_NAME="${PROJECT_NAME:-my-project}"
PROJECT_ROOT="${PROJECT_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
TEMPLATE_ROOT="${TEMPLATE_ROOT:-$PROJECT_ROOT/.qwen/template}"

# -----------------------------------------------------------------------------
# Определение типа проекта (автоматически)
# -----------------------------------------------------------------------------

detect_project_type() {
  if [ -f "$PROJECT_ROOT/package.json" ]; then
    echo "nodejs"
  elif [ -f "$PROJECT_ROOT/requirements.txt" ]; then
    echo "python"
  elif [ -f "$PROJECT_ROOT/Cargo.toml" ]; then
    echo "rust"
  elif [ -f "$PROJECT_ROOT/go.mod" ]; then
    echo "go"
  elif [ -f "$PROJECT_ROOT/pom.xml" ]; then
    echo "java"
  else
    echo "unknown"
  fi
}

PROJECT_TYPE="${PROJECT_TYPE:-auto}"
if [ "$PROJECT_TYPE" = "auto" ]; then
  PROJECT_TYPE=$(detect_project_type)
fi

# -----------------------------------------------------------------------------
# Пути (универсальные, зависят от типа проекта)
# -----------------------------------------------------------------------------

get_backend_dir() {
  case "$PROJECT_TYPE" in
    nodejs)
      echo "$PROJECT_ROOT"
      ;;
    python)
      if [ -d "$PROJECT_ROOT/backend" ]; then
        echo "$PROJECT_ROOT/backend"
      else
        echo "$PROJECT_ROOT"
      fi
      ;;
    rust)
      echo "$PROJECT_ROOT"
      ;;
    go)
      echo "$PROJECT_ROOT"
      ;;
    java)
      echo "$PROJECT_ROOT"
      ;;
    *)
      echo "$PROJECT_ROOT"
      ;;
  esac
}

get_test_dir() {
  case "$PROJECT_TYPE" in
    nodejs)
      echo "$PROJECT_ROOT/tests"
      ;;
    python)
      echo "$BACKEND_DIR/tests"
      ;;
    rust)
      echo "$PROJECT_ROOT/tests"
      ;;
    go)
      echo "$PROJECT_ROOT"
      ;;
    java)
      echo "$PROJECT_ROOT/src/test"
      ;;
    *)
      echo "$PROJECT_ROOT/tests"
      ;;
  esac
}

get_test_cmd() {
  case "$PROJECT_TYPE" in
    nodejs)
      echo "npm test"
      ;;
    python)
      echo "pytest"
      ;;
    rust)
      echo "cargo test"
      ;;
    go)
      echo "go test"
      ;;
    java)
      echo "mvn test"
      ;;
    *)
      echo "make test"
      ;;
  esac
}

BACKEND_DIR="${BACKEND_DIR:-$(get_backend_dir)}"
TEST_DIR="${TEST_DIR:-$(get_test_dir)}"
TEST_CMD="${TEST_CMD:-$(get_test_cmd)}"

# -----------------------------------------------------------------------------
# Директории
# -----------------------------------------------------------------------------

# Состояние
STATE_DIR="${STATE_DIR:-$PROJECT_ROOT/.qwen/state}"
BUGS_DIR="${BUGS_DIR:-$STATE_DIR/bugs}"
TASKS_DIR="${TASKS_DIR:-$STATE_DIR/tasks}"

# Скрипты
SCRIPTS_DIR="${SCRIPTS_DIR:-$PROJECT_ROOT/.qwen/scripts}"
BUG_TRACKING_SCRIPTS="${BUG_TRACKING_SCRIPTS:-$SCRIPTS_DIR/bug-tracking}"
QUALITY_GATES_SCRIPTS="${QUALITY_GATES_SCRIPTS:-$SCRIPTS_DIR/quality-gates}"

# -----------------------------------------------------------------------------
# Реестры
# -----------------------------------------------------------------------------

BUG_REGISTRY="${BUG_REGISTRY:-$STATE_DIR/bug-registry.json}"
TASK_REGISTRY="${TASK_REGISTRY:-$STATE_DIR/task-registry.json}"

# -----------------------------------------------------------------------------
# Транспорт
# -----------------------------------------------------------------------------

TRANSPORT_METHOD="${TRANSPORT_METHOD:-git}"
TEMPLATE_WEBHOOK="${TEMPLATE_WEBHOOK:-}"

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
  mkdir -p "$STATE_DIR" "$BUGS_DIR" "$TASKS_DIR"
  mkdir -p "$BUG_TRACKING_SCRIPTS" "$QUALITY_GATES_SCRIPTS"
}

# Проверка конфигурации
check_config() {
  if [ ! -d "$PROJECT_ROOT" ]; then
    echo "❌ PROJECT_ROOT не существует: $PROJECT_ROOT"
    return 1
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
export PROJECT_NAME PROJECT_TYPE PROJECT_ROOT TEMPLATE_ROOT
export BACKEND_DIR TEST_DIR TEST_CMD
export STATE_DIR BUGS_DIR TASKS_DIR
export SCRIPTS_DIR BUG_TRACKING_SCRIPTS QUALITY_GATES_SCRIPTS
export BUG_REGISTRY TASK_REGISTRY
export TRANSPORT_METHOD TEMPLATE_WEBHOOK
export MAX_WARNINGS MAX_FAILED MAX_ERRORS
