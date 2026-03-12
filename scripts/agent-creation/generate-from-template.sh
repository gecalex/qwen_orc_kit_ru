#!/bin/bash
# Скрипт генерации агентов из шаблонов
# Назначение: Создание новых агентов (оркестраторов и воркеров) на основе шаблонов

set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Функция для вывода сообщений
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Проверка аргументов
if [ $# -lt 4 ]; then
    echo "Использование: $0 <agent_type> <domain> <name> <description>"
    echo "  agent_type: orc (оркестратор) или work (воркер)"
    echo "  domain: dev, frontend, backend, testing, research, security"
    echo "  name: имя агента в формате kebab-case"
    echo "  description: описание агента"
    exit 1
fi

AGENT_TYPE=$1
DOMAIN=$2
NAME=$3
DESCRIPTION=$4

# Проверка типа агента
if [[ "$AGENT_TYPE" != "orc" && "$AGENT_TYPE" != "work" ]]; then
    log_error "Неверный тип агента: $AGENT_TYPE. Допустимые значения: orc, work"
    exit 1
fi

# Проверка домена
VALID_DOMAINS=("dev" "frontend" "backend" "testing" "research" "security")
if [[ ! " ${VALID_DOMAINS[@]} " =~ " ${DOMAIN} " ]]; then
    log_error "Неверный домен: $DOMAIN. Допустимые значения: ${VALID_DOMAINS[*]}"
    exit 1
fi

# Проверка формата имени (kebab-case)
if [[ ! "$NAME" =~ ^[a-z][a-z0-9-]*[a-z0-9]$ ]]; then
    log_error "Неверный формат имени: $NAME. Имя должно быть в формате kebab-case (например: my-agent-name)"
    exit 1
fi

# Формирование полного имени агента
FULL_NAME="${AGENT_TYPE}_${DOMAIN}_${NAME}"

# Проверка, существует ли уже агент с таким именем
AGENT_FILE=".qwen/agents/${FULL_NAME}.md"
if [ -f "$AGENT_FILE" ]; then
    log_warning "Агент с именем $FULL_NAME уже существует: $AGENT_FILE"
    read -p "Перезаписать файл? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Создание агента отменено."
        exit 0
    fi
fi

# Определение пути к шаблону
if [ "$AGENT_TYPE" = "orc" ]; then
    TEMPLATE_FILE=".qwen/templates/orchestrator-template.md"
    COLOR="purple"
else
    TEMPLATE_FILE=".qwen/templates/worker-template.md"
    COLOR="blue"
fi

# Проверка существования шаблона
if [ ! -f "$TEMPLATE_FILE" ]; then
    log_error "Шаблон не найден: $TEMPLATE_FILE"
    exit 1
fi

# Создание директории, если не существует
mkdir -p .qwen/agents

# Чтение шаблона и замена переменных
log_info "Создание агента из шаблона: $TEMPLATE_FILE"

# Создание файла агента с заменой переменных
sed -e "s/{domain}/${DOMAIN}/g" \
    -e "s/{name}/${NAME}/g" \
    -e "s/{domain_color}/${COLOR}/g" \
    -e "s/{description}/${DESCRIPTION}/g" \
    "$TEMPLATE_FILE" > "$AGENT_FILE"

# Заменяем оставшиеся заполнители в описании
sed -i "s/Краткое описание функций .*/${DESCRIPTION}/g" "$AGENT_FILE"

log_success "Агент $FULL_NAME успешно создан из шаблона: $AGENT_FILE"

# Обновление индекса агентов (если файл существует)
if [ -f "docs/agents-index.md" ]; then
    log_info "Обновление индекса агентов..."
    if grep -q "$FULL_NAME" "docs/agents-index.md"; then
        log_warning "Агент $FULL_NAME уже присутствует в индексе"
    else
        echo "- [$FULL_NAME](../$AGENT_FILE) - $DESCRIPTION" >> "docs/agents-index.md"
        log_success "Агент добавлен в индекс: docs/agents-index.md"
    fi
else
    log_warning "Файл индекса агентов docs/agents-index.md не найден"
fi

# Запуск проверок качества
log_info "Запуск проверок качества..."
if [ -f "scripts/validation/check-yaml-headers.sh" ]; then
    log_info "Проверка YAML заголовков..."
    bash scripts/validation/check-yaml-headers.sh || log_warning "Обнаружены проблемы в YAML заголовке"
else
    log_warning "Скрипт проверки YAML заголовков не найден"
fi

if [ -f "scripts/validation/check-agent-structure.sh" ]; then
    log_info "Проверка структуры агента..."
    bash scripts/validation/check-agent-structure.sh || log_warning "Обнаружены проблемы в структуре агента"
else
    log_warning "Скрипт проверки структуры агента не найден"
fi

log_info "Создание агента завершено!"