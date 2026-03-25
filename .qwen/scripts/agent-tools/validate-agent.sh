#!/bin/bash
# Скрипт валидации агентов
# Назначение: Проверка созданных агентов на соответствие стандартам

set -e

# Цвета
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Проверка аргументов
if [ $# -lt 1 ]; then
    echo "Использование: $0 <agent_name>"
    echo "  agent_name: имя агента (например: work_frontend_specialist)"
    exit 1
fi

AGENT_NAME=$1
AGENT_FILE=".qwen/agents/${AGENT_NAME}.md"

log_info "Валидация агента: $AGENT_NAME"

# Проверка существования файла
if [ ! -f "$AGENT_FILE" ]; then
    log_error "Агент не найден: $AGENT_FILE"
    exit 1
fi

log_success "✅ Файл агента существует"

# Проверка YAML frontmatter
log_info "Проверка YAML frontmatter..."
if grep -q "^---$" "$AGENT_FILE" && grep -q "^name:" "$AGENT_FILE" && grep -q "^description:" "$AGENT_FILE"; then
    log_success "✅ YAML frontmatter корректен"
else
    log_error "❌ YAML frontmatter отсутствует или некорректен"
    exit 1
fi

# Проверка имени агента
log_info "Проверка имени агента..."
if grep -q "^name: ${AGENT_NAME}$" "$AGENT_FILE"; then
    log_success "✅ Имя агента совпадает"
else
    log_error "❌ Имя агента в файле не совпадает с ожидаемым"
    exit 1
fi

# Проверка типа агента (orc_* или work_*)
log_info "Проверка типа агента..."
if [[ "$AGENT_NAME" =~ ^orc_ ]]; then
    log_success "✅ Оркестратор (orc_*)"
elif [[ "$AGENT_NAME" =~ ^work_ ]]; then
    log_success "✅ Воркер (work_*)"
else
    log_error "❌ Неверный префикс агента (должен быть orc_* или work_*)"
    exit 1
fi

# Проверка домена
log_info "Проверка домена..."
VALID_DOMAINS="dev|frontend|backend|testing|research|security|doc|planning"
if [[ "$AGENT_NAME" =~ ^(orc|work)_(${VALID_DOMAINS})_ ]]; then
    log_success "✅ Домен корректен"
else
    log_warning "⚠️  Домен может быть некорректным (проверьте вручную)"
fi

# Проверка наличия description
log_info "Проверка описания..."
if grep -q "^description:" "$AGENT_FILE"; then
    log_success "✅ Описание присутствует"
else
    log_error "❌ Описание отсутствует"
    exit 1
fi

# Проверка наличия инструментов
log_info "Проверка инструментов..."
if grep -q "^tools:" "$AGENT_FILE"; then
    log_success "✅ Инструменты указаны"
else
    log_warning "⚠️  Инструменты не указаны (может быть намеренно)"
fi

# Проверка наличия раздела "Назначение" или "## Назначение"
log_info "Проверка структуры..."
if grep -q "## Назначение\|## Назначение\|## Assignment" "$AGENT_FILE"; then
    log_success "✅ Структура агента корректна"
else
    log_warning "⚠️  Раздел 'Назначение' не найден"
fi

# Проверка на наличие bash-кода с переменными (проблема Qwen Code CLI)
log_info "Проверка на проблемные переменные..."
if grep -qE '\$\{[a-z_]+\}' "$AGENT_FILE"; then
    log_warning "⚠️  Обнаружены переменные в формате \${var} — Qwen Code CLI может требовать их как параметры!"
else
    log_success "✅ Проблемные переменные не обнаружены"
fi

log_success "========================================"
log_success "  Валидация завершена: $AGENT_NAME"
log_success "  Статус: ПРОЙДЕНА"
log_success "========================================"

exit 0
