#!/bin/bash

# =============================================================================
# prepare-release.sh - Подготовка к релизу расширения
# =============================================================================
# 
# Назначение: Подготовка к релизу (обновление версии, changelog)
# 
# Использование:
#   ./prepare-release.sh <версия>
# 
# Примеры:
#   ./prepare-release.sh 0.8.0
#   ./prepare-release.sh 1.0.0
# 
# =============================================================================

set -e

# Константы
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$(dirname "$SCRIPT_DIR")")")"
QWEN_DIR="$PROJECT_ROOT/.qwen"
MANIFEST_FILE="$QWEN_DIR/qwen-extension.json"
VERSION_FILE="$PROJECT_ROOT/.version"
PACKAGE_JSON="$PROJECT_ROOT/package.json"
CHANGELOG_FILE="$PROJECT_ROOT/CHANGELOG.md"

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Функции логирования
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_step() { echo -e "${CYAN}[STEP]${NC} $1"; }

# Проверка аргументов
check_arguments() {
    if [ $# -eq 0 ]; then
        log_error "Не указана версия!"
        echo ""
        echo "Использование:"
        echo "  $0 <версия>"
        echo ""
        echo "Примеры:"
        echo "  $0 0.8.0"
        echo "  $0 1.0.0"
        echo ""
        exit 1
    fi

    VERSION="$1"

    # Проверка формата версии (semver)
    if ! [[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        log_error "Неверный формат версии! Используйте формат X.Y.Z (например, 0.8.0)"
        exit 1
    fi

    log_info "Версия для релиза: $VERSION"
}

# Проверка окружения
check_environment() {
    log_step "Проверка окружения..."

    # Проверка Git
    if ! command -v git &> /dev/null; then
        log_error "Git не установлен!"
        exit 1
    fi
    log_success "Git установлен"

    # Проверка jq
    if ! command -v jq &> /dev/null; then
        log_error "jq не установлен! Установите: sudo apt-get install jq"
        exit 1
    fi
    log_success "jq установлен"

    # Проверка манифеста
    if [ ! -f "$MANIFEST_FILE" ]; then
        log_error "Манифест не найден: $MANIFEST_FILE"
        exit 1
    fi
    log_success "Манифест найден"

    # Проверка QWEN.md
    if [ ! -f "$QWEN_DIR/QWEN.md" ]; then
        log_error "QWEN.md не найден: $QWEN_DIR/QWEN.md"
        exit 1
    fi
    log_success "QWEN.md найден"

    # Проверка, что мы в корне проекта
    if [ ! -f "$PACKAGE_JSON" ]; then
        log_error "package.json не найден! Убедитесь, что скрипт запущен из корня проекта"
        exit 1
    fi
    log_success "Корень проекта определён верно"

    echo ""
}

# Обновление версии в манифесте
update_manifest_version() {
    log_step "Обновление версии в манифесте..."

    # Сохранить старую версию
    OLD_VERSION=$(jq -r '.version' "$MANIFEST_FILE")
    log_info "Старая версия: $OLD_VERSION"

    # Обновить версию
    jq --arg version "$VERSION" '.version = $version' "$MANIFEST_FILE" > "$MANIFEST_FILE.tmp"
    mv "$MANIFEST_FILE.tmp" "$MANIFEST_FILE"

    # Проверить обновление
    NEW_VERSION=$(jq -r '.version' "$MANIFEST_FILE")
    if [ "$NEW_VERSION" != "$VERSION" ]; then
        log_error "Не удалось обновить версию в манифесте!"
        exit 1
    fi

    log_success "Версия обновлена: $OLD_VERSION → $NEW_VERSION"
    echo ""
}

# Обновление версии в package.json
update_package_version() {
    log_step "Обновление версии в package.json..."

    if [ ! -f "$PACKAGE_JSON" ]; then
        log_warning "package.json не найден, пропускаем"
        return
    fi

    OLD_VERSION=$(jq -r '.version' "$PACKAGE_JSON")
    log_info "Старая версия: $OLD_VERSION"

    jq --arg version "$VERSION" '.version = $version' "$PACKAGE_JSON" > "$PACKAGE_JSON.tmp"
    mv "$PACKAGE_JSON.tmp" "$PACKAGE_JSON"

    NEW_VERSION=$(jq -r '.version' "$PACKAGE_JSON")
    if [ "$NEW_VERSION" != "$VERSION" ]; then
        log_error "Не удалось обновить версию в package.json!"
        exit 1
    fi

    log_success "Версия обновлена: $OLD_VERSION → $NEW_VERSION"
    echo ""
}

# Обновление файла .version
update_version_file() {
    log_step "Обновление файла .version..."

    echo "$VERSION" > "$VERSION_FILE"

    log_success "Файл .version обновлён: $VERSION"
    echo ""
}

# Генерация changelog
generate_changelog() {
    log_step "Генерация changelog..."

    # Получить предыдущий тег
    PREV_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "")

    if [ -z "$PREV_TAG" ]; then
        log_warning "Предыдущий тег не найден (первый релиз)"
        CHANGELOG_ENTRIES=$(git log --pretty=format:"* %s (%h)" --no-merges | head -20)
    else
        log_info "Предыдущий тег: $PREV_TAG"
        CHANGELOG_ENTRIES=$(git log --pretty=format:"* %s (%h)" --no-merges "$PREV_TAG"..HEAD | head -20)
    fi

    # Форматировать дату
    RELEASE_DATE=$(date +%Y-%m-%d)

    # Создать запись changelog
    CHANGELOG_ENTRY=$(cat << EOF

## [$VERSION] - $RELEASE_DATE

### Изменения

$CHANGELOG_ENTRIES

EOF
)

    # Добавить в начало CHANGELOG.md (после заголовка)
    if [ -f "$CHANGELOG_FILE" ]; then
        # Прочитать существующий changelog
        EXISTING_CONTENT=$(cat "$CHANGELOG_FILE")
        
        # Записать новый заголовок и содержимое
        echo "$EXISTING_CONTENT" | head -1 > "$CHANGELOG_FILE.tmp"
        echo "" >> "$CHANGELOG_FILE.tmp"
        echo "$CHANGELOG_ENTRY" >> "$CHANGELOG_FILE.tmp"
        echo "$EXISTING_CONTENT" | tail -n +2 >> "$CHANGELOG_FILE.tmp"
        
        mv "$CHANGELOG_FILE.tmp" "$CHANGELOG_FILE"
        log_success "CHANGELOG.md обновлён"
    else
        # Создать новый CHANGELOG.md
        cat > "$CHANGELOG_FILE" << EOF
# Changelog

$CHANGELOG_ENTRY
EOF
        log_success "CHANGELOG.md создан"
    fi

    echo ""
}

# Проверка изменений
check_changes() {
    log_step "Проверка изменений..."

    echo "📊 Изменения:"
    git diff --stat

    echo ""

    # Проверить, есть ли изменения
    if git diff --quiet; then
        log_warning "Нет изменений для коммита"
    else
        log_success "Обнаружены изменения"
    fi

    echo ""
}

# Создание черновика коммита
create_commit_draft() {
    log_step "Создание черновика коммита..."

    # Добавить изменённые файлы
    git add "$MANIFEST_FILE" "$PACKAGE_JSON" "$VERSION_FILE" "$CHANGELOG_FILE" 2>/dev/null || true

    # Показать статус
    git status --short

    echo ""
    log_info "Файлы добавлены в staging area"
    log_warning "Коммит НЕ создан автоматически!"
    echo ""
    echo "Следующие шаги:"
    echo "  1. Проверьте изменения: git diff --cached"
    echo "  2. Создайте коммит: git commit -m \"chore: prepare release v$VERSION\""
    echo "  3. Запустите create-release.sh: ./scripts/release/create-release.sh $VERSION"
    echo ""
}

# Основная функция
main() {
    echo ""
    echo "========================================"
    echo "🚀 Подготовка к релизу v$VERSION"
    echo "========================================"
    echo ""

    check_arguments "$@"
    check_environment
    update_manifest_version
    update_package_version
    update_version_file
    generate_changelog
    check_changes
    create_commit_draft

    echo ""
    echo "========================================"
    log_success "Подготовка к релизу v$VERSION завершена!"
    echo "========================================"
    echo ""
}

# Запуск
main "$@"
