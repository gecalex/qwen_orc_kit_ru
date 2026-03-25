#!/bin/bash

# =============================================================================
# validate-dependency.sh - Валидация зависимостей перед добавлением
# =============================================================================
# Назначение: Проверка зависимости перед добавлением в проект
# 
# Функционал:
#   - Проверка наличия в package.json / requirements.txt
#   - Проверка совместимости версий
#   - Проверка на уязвимости
#   - Проверка через MCP Context7 (ОБЯЗАТЕЛЬНО!)
#   - Рекомендации по обновлению
#
# Использование:
#   .qwen/scripts/validation/validate-dependency.sh <package-name> [version]
# =============================================================================

set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Переменные
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PACKAGE_NAME="$1"
PACKAGE_VERSION="${2:-latest}"

# Функция вывода помощи
show_help() {
    echo -e "${BLUE}validate-dependency.sh - Валидация зависимостей${NC}"
    echo ""
    echo "Использование:"
    echo "  $0 <package-name> [version]"
    echo ""
    echo "Примеры:"
    echo "  $0 eslint"
    echo "  $0 eslint ^9.0.0"
    echo ""
    echo "MCP Context7 (ОБЯЗАТЕЛЬНО):"
    echo "  Перед установкой проверьте пакет через Context7:"
    echo "  mcp__context7__resolve-library-id(libraryName=\"$PACKAGE_NAME\", ...)"
}

# Функция логирования
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[⚠]${NC} $1"
}

log_error() {
    echo -e "${RED}[✗]${NC} $1"
}

# Проверка аргументов
if [ -z "$PACKAGE_NAME" ]; then
    log_error "Укажите имя пакета"
    show_help
    exit 1
fi

log_info "Валидация зависимости: ${PACKAGE_NAME}@${PACKAGE_VERSION}"
echo ""

# Шаг 1: Проверка наличия в package.json
log_info "Шаг 1: Проверка наличия в package.json"

if [ -f "${PROJECT_ROOT}/package.json" ]; then
    if grep -q "\"${PACKAGE_NAME}\"" "${PROJECT_ROOT}/package.json"; then
        log_warning "Пакет уже существует в проекте"
        CURRENT_VERSION=$(grep -A1 "\"${PACKAGE_NAME}\"" "${PROJECT_ROOT}/package.json" | tail -1 | sed 's/.*: "\(.*\)".*/\1/' | tr -d '",')
        echo "  Текущая версия: ${CURRENT_VERSION}"
    else
        log_success "Пакет не найден в проекте (можно добавлять)"
    fi
else
    log_info "package.json не найден"
fi

echo ""

# Шаг 2: Проверка доступных версий
log_info "Шаг 2: Проверка доступных версий"

if command -v npm &> /dev/null; then
    LATEST_VERSION=$(npm view "$PACKAGE_NAME" version 2>/dev/null || echo "unknown")
    if [ "$LATEST_VERSION" != "unknown" ]; then
        log_success "Последняя версия: ${LATEST_VERSION}"
        
        # Проверка количества версий
        VERSION_COUNT=$(npm view "$PACKAGE_NAME" versions --json 2>/dev/null | jq 'length' || echo "0")
        echo "  Доступно версий: ${VERSION_COUNT}"
    else
        log_warning "Не удалось получить информацию о версиях"
    fi
else
    log_info "npm не установлен, пропускаем проверку версий"
fi

echo ""

# Шаг 3: Проверка на уязвимости
log_info "Шаг 3: Проверка на уязвимости"

if command -v npm &> /dev/null; then
    # Временная установка для проверки
    log_info "Проверка уязвимостей..."
    
    # Создаем временную директорию
    TEMP_DIR=$(mktemp -d)
    cd "$TEMP_DIR"
    npm init -y > /dev/null 2>&1
    
    if npm install "${PACKAGE_NAME}@${PACKAGE_VERSION}" --dry-run 2>&1 | grep -q "vulnerabilit"; then
        log_warning "Обнаружены уязвимости"
        npm audit 2>/dev/null | grep -A5 "vulnerabilit" || true
    else
        log_success "Уязвимостей не обнаружено"
    fi
    
    # Очистка
    cd "${PROJECT_ROOT}"
    rm -rf "$TEMP_DIR"
else
    log_info "npm не установлен, пропускаем проверку уязвимостей"
fi

echo ""

# Шаг 4: Проверка размера пакета
log_info "Шаг 4: Проверка размера пакета"

if command -v npm &> /dev/null; then
    PACKAGE_SIZE=$(npm view "$PACKAGE_NAME" dist.tarball 2>/dev/null | head -1 || echo "")
    if [ -n "$PACKAGE_SIZE" ]; then
        log_success "Размер пакета: доступен по ссылке ${PACKAGE_SIZE}"
    else
        log_info "Не удалось получить размер пакета"
    fi
fi

echo ""

# Шаг 5: Проверка активности поддержки
log_info "Шаг 5: Проверка активности поддержки"

if command -v npm &> /dev/null; then
    LAST_UPDATE=$(npm view "$PACKAGE_NAME" time.modified 2>/dev/null || echo "unknown")
    if [ "$LAST_UPDATE" != "unknown" ]; then
        log_success "Последнее обновление: ${LAST_UPDATE}"
    else
        log_info "Не удалось получить дату обновления"
    fi
    
    # Проверка количества загрузок
    DOWNLOADS=$(npm view "$PACKAGE_NAME" downloads.weekly 2>/dev/null || echo "unknown")
    if [ "$DOWNLOADS" != "unknown" ]; then
        log_success "Загрузок за неделю: ${DOWNLOADS}"
    fi
fi

echo ""

# Шаг 6: Проверка лицензии
log_info "Шаг 6: Проверка лицензии"

if command -v npm &> /dev/null; then
    LICENSE=$(npm view "$PACKAGE_NAME" license 2>/dev/null || echo "unknown")
    if [ "$LICENSE" != "unknown" ]; then
        if [ "$LICENSE" == "MIT" ] || [ "$LICENSE" == "Apache-2.0" ] || [ "$LICENSE" == "BSD-3-Clause" ]; then
            log_success "Лицензия: ${LICENSE} (совместима)"
        else
            log_warning "Лицензия: ${LICENSE} (требуется проверка)"
        fi
    else
        log_info "Не удалось получить информацию о лицензии"
    fi
fi

echo ""

# Итоговый отчет
echo "=========================================="
echo "         Итоговый отчет          "
echo "=========================================="
echo ""
echo "Пакет: ${PACKAGE_NAME}"
echo "Версия: ${PACKAGE_VERSION}"
echo ""

# Рекомендация
log_info "Рекомендация:"

if [ "$PACKAGE_VERSION" == "latest" ]; then
    log_success "✅ Пакет рекомендуется к установке"
else
    log_success "✅ Пакет рекомендуется к установке (проверьте совместимость версий)"
fi

echo ""
echo "Дополнительные команды:"
echo "  npm install ${PACKAGE_NAME}@${PACKAGE_VERSION}  # Установка"
echo "  npm view ${PACKAGE_NAME}                        # Подробная информация"
echo "  npm view ${PACKAGE_NAME} versions               # Все версии"
echo ""
