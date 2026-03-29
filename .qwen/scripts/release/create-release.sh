#!/bin/bash

# =============================================================================
# create-release.sh - Создание релиза расширения
# =============================================================================
# 
# Назначение: Создание Git тега и push для запуска CI/CD
# 
# Использование:
#   ./create-release.sh <версия>
# 
# Примеры:
#   ./create-release.sh 0.8.0
#   ./create-release.sh 1.0.0
# 
# =============================================================================

set -e

# Константы
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$(dirname "$SCRIPT_DIR")")")"
QWEN_DIR="$PROJECT_ROOT/.qwen"
MANIFEST_FILE="$QWEN_DIR/qwen-extension.json"
VERSION_FILE="$PROJECT_ROOT/.version"

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
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

    # Проверка манифеста
    if [ ! -f "$MANIFEST_FILE" ]; then
        log_error "Манифест не найден: $MANIFEST_FILE"
        exit 1
    fi
    log_success "Манифест найден"

    # Проверка версии в манифесте
    MANIFEST_VERSION=$(jq -r '.version' "$MANIFEST_FILE")
    if [ "$MANIFEST_VERSION" != "$VERSION" ]; then
        log_error "Версия в манифесте ($MANIFEST_VERSION) не совпадает с указанной ($VERSION)!"
        log_info "Запустите сначала: ./prepare-release.sh $VERSION"
        exit 1
    fi
    log_success "Версия в манифесте совпадает: $MANIFEST_VERSION"

    # Проверка .version
    if [ ! -f "$VERSION_FILE" ]; then
        log_error "Файл .version не найден!"
        exit 1
    fi

    FILE_VERSION=$(cat "$VERSION_FILE")
    if [ "$FILE_VERSION" != "$VERSION" ]; then
        log_error "Версия в .version ($FILE_VERSION) не совпадает с указанной ($VERSION)!"
        exit 1
    fi
    log_success "Версия в .version совпадает: $FILE_VERSION"

    # Проверка текущей ветки
    CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
    if [ "$CURRENT_BRANCH" != "main" ]; then
        log_warning "Текущая ветка: $CURRENT_BRANCH (рекомендуется main)"
        read -p "Продолжить? (y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Отменено пользователем"
            exit 0
        fi
    else
        log_success "Текущая ветка: main"
    fi

    # Проверка незакоммиченных изменений
    if ! git diff --quiet; then
        log_error "Есть незакоммиченные изменения!"
        log_info "Закоммитьте изменения перед созданием релиза"
        git status --short
        exit 1
    fi
    log_success "Нет незакоммиченных изменений"

    echo ""
}

# Проверка существующего тега
check_existing_tag() {
    log_step "Проверка существующих тегов..."

    TAG_NAME="v$VERSION"

    if git rev-parse "$TAG_NAME" >/dev/null 2>&1; then
        log_error "Тег $TAG_NAME уже существует!"
        log_info "Удалите существующий тег или используйте другую версию"
        echo ""
        echo "Для удаления тега:"
        echo "  git tag -d $TAG_NAME"
        echo "  git push origin :refs/tags/$TAG_NAME"
        echo ""
        exit 1
    fi

    log_success "Тег $TAG_NAME не существует, можно создавать"
    echo ""
}

# Создание Git тега
create_git_tag() {
    log_step "Создание Git тега..."

    TAG_NAME="v$VERSION"
    RELEASE_DATE=$(date +%Y-%m-%d)

    # Получить changelog для последней версии
    PREV_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "")

    if [ -z "$PREV_TAG" ]; then
        CHANGELOG_SUMMARY="Первый релиз"
    else
        CHANGELOG_SUMMARY=$(git log --pretty=format:"%s" --no-merges "$PREV_TAG"..HEAD | head -5 | tr '\n' ', ' | sed 's/,$//')
    fi

    # Создать аннотированный тег
    TAG_MESSAGE="Release $TAG_NAME ($RELEASE_DATE)

$CHANGELOG_SUMMARY

Installation:
  qwen extensions install https://github.com/\$(git remote get-url origin | sed 's/.*://' | sed 's/\.git$//') --ref $TAG_NAME

Update:
  qwen extensions update qwen-orchestrator-kit"

    git tag -a "$TAG_NAME" -m "$TAG_MESSAGE"

    log_success "Тег $TAG_NAME создан"
    echo ""
}

# Push тега на GitHub
push_tag() {
    log_step "Push тега на GitHub..."

    TAG_NAME="v$VERSION"

    # Проверка наличия remote
    if ! git remote get-url origin >/dev/null 2>&1; then
        log_error "Remote 'origin' не найден!"
        exit 1
    fi

    REMOTE_URL=$(git remote get-url origin)
    log_info "Remote: $REMOTE_URL"

    # Push тега
    log_info "Отправка тега $TAG_NAME..."
    git push origin "$TAG_NAME"

    log_success "Тег отправлен на GitHub"
    echo ""
}

# Проверка статуса CI/CD
check_ci_status() {
    log_step "Проверка статуса CI/CD..."

    TAG_NAME="v$VERSION"

    echo ""
    log_info "GitHub Actions должен автоматически запустить workflow 'Release Extension'"
    echo ""
    echo "🔗 Ссылки:"
    echo "   Actions: https://github.com/$(git remote get-url origin | sed 's/.*github.com[:/]/' | sed 's/\.git$//')/actions"
    echo "   Release: https://github.com/$(git remote get-url origin | sed 's/.*github.com[:/]/' | sed 's/\.git$//')/releases/tag/$TAG_NAME"
    echo ""

    log_warning "Проверьте статус workflow в течение 1-2 минут"
    echo ""
}

# Вывод итоговой информации
print_summary() {
    echo ""
    echo "========================================"
    echo -e "${MAGENTA}🎉 Релиз v$VERSION создан!${NC}"
    echo "========================================"
    echo ""
    echo "✅ Выполненные шаги:"
    echo "   1. Проверка окружения"
    echo "   2. Проверка версии в манифесте"
    echo "   3. Создание Git тега v$VERSION"
    echo "   4. Push тега на GitHub"
    echo ""
    echo "🔄 Следующие шаги:"
    echo "   1. Проверьте GitHub Actions: workflow 'Release Extension'"
    echo "   2. Дождитесь создания GitHub Release"
    echo "   3. Проверьте опубликованный релиз"
    echo ""
    echo "📦 Пользователи смогут обновиться:"
    echo "   qwen extensions update qwen-orchestrator-kit"
    echo ""
    echo "🔗 GitHub Release:"
    echo "   https://github.com/$(git remote get-url origin | sed 's/.*github.com[:/]/' | sed 's/\.git$//')/releases/tag/v$VERSION"
    echo ""
}

# Основная функция
main() {
    echo ""
    echo "========================================"
    echo "🚀 Создание релиза v$VERSION"
    echo "========================================"
    echo ""

    check_arguments "$@"
    check_environment
    check_existing_tag
    create_git_tag
    push_tag
    check_ci_status
    print_summary
}

# Запуск
main "$@"
