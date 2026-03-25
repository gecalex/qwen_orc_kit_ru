#!/bin/bash
# =============================================================================
# auto-tag-release.sh
# =============================================================================
# Назначение: Автоматическое создание тегов версий
# 
# Использование:
#   .qwen/scripts/git/auto-tag-release.sh "<version>" "<description>"
#
# Пример:
#   .qwen/scripts/git/auto-tag-release.sh "v0.6.0" "Release v0.6.0: Feedback System"
#
# Функционал:
#   - Анализ завершённых фаз
#   - Генерация версии (semver)
#   - Создание аннотированного тега
#   - Push тега на GitHub
#   - Обновление CHANGELOG
#
# Выход:
#   Успех: имя созданного тега (stdout)
#   Ошибка: код ошибки + сообщение (stderr)
# =============================================================================

set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Функция вывода ошибок
error() {
    echo -e "${RED}❌ ОШИБКА:${NC} $1" >&2
}

# Функция вывода предупреждений
warn() {
    echo -e "${YELLOW}⚠️  ПРЕДУПРЕЖДЕНИЕ:${NC} $1" >&2
}

# Функция вывода информации
info() {
    echo -e "${BLUE}ℹ️  ИНФО:${NC} $1"
}

# Функция вывода успеха
success() {
    echo -e "${GREEN}✅ УСПЕХ:${NC} $1"
}

# Функция валидации версии semver
validate_semver() {
    local version="$1"
    
    # Проверка формата vX.Y.Z или X.Y.Z
    if [[ "$version" =~ ^v?[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9.]+)?(\+[a-zA-Z0-9.]+)?$ ]]; then
        return 0
    else
        error "Неверный формат версии. Ожидается формат: vX.Y.Z или X.Y.Z"
        error "Примеры: v1.0.0, 1.0.0, v1.0.0-beta.1, 1.0.0+build.123"
        return 1
    fi
}

# Функция нормализации версии (добавляет 'v' если нет)
normalize_version() {
    local version="$1"
    if [[ "$version" =~ ^v ]]; then
        echo "$version"
    else
        echo "v$version"
    fi
}

# Функция получения последнего тега
get_last_tag() {
    git describe --tags --abbrev=0 2>/dev/null || echo ""
}

# Функция получения последнего тега semver
get_last_semver_tag() {
    git tag -l 'v*' --sort=-v:refname 2>/dev/null | head -n 1 || echo ""
}

# Функция анализа завершенных фаз
analyze_completed_phases() {
    local phases_count=0
    local reports_dir=".qwen/reports"
    
    if [ -d "$reports_dir" ]; then
        phases_count=$(find "$reports_dir" -name "*report*.md" -type f 2>/dev/null | wc -l)
    fi
    
    # Проверка спецификаций
    local specs_count=0
    if [ -d ".qwen/specify/specs" ]; then
        specs_count=$(find ".qwen/specify/specs" -name "*.md" -type f 2>/dev/null | wc -l)
    fi
    
    echo "phases=$phases_count,specs=$specs_count"
}

# Функция генерации CHANGELOG записи
generate_changelog_entry() {
    local version="$1"
    local description="$2"
    local date=$(date +"%Y-%m-%d")
    
    cat << EOF

## [$version] - $date

### Изменения
- $description

### Технические детали
EOF
}

# Функция обновления CHANGELOG
update_changelog() {
    local version="$1"
    local description="$2"
    local changelog_file="CHANGELOG.md"
    
    if [ ! -f "$changelog_file" ]; then
        warn "Файл CHANGELOG.md не найден, создаю новый..."
        echo "# Changelog" > "$changelog_file"
        echo "" >> "$changelog_file"
        echo "Все значительные изменения в проекте будут задокументированы в этом файле." >> "$changelog_file"
    fi
    
    # Генерация записи
    local entry=$(generate_changelog_entry "$version" "$description")
    
    # Вставка после заголовка
    local temp_file=$(mktemp)
    local header_line=$(grep -n "^# Changelog" "$changelog_file" | head -n 1 | cut -d: -f1)
    
    if [ -n "$header_line" ]; then
        # Вставляем после заголовка и описания
        head -n $((header_line + 2)) "$changelog_file" > "$temp_file"
        echo "$entry" >> "$temp_file"
        tail -n +$((header_line + 3)) "$changelog_file" >> "$temp_file"
    else
        # Если заголовка нет, добавляем в начало
        echo "# Changelog" > "$temp_file"
        echo "" >> "$temp_file"
        echo "$entry" >> "$temp_file"
        cat "$changelog_file" >> "$temp_file"
    fi
    
    mv "$temp_file" "$changelog_file"
    
    success "CHANGELOG.md обновлен"
}

# Функция создания аннотированного тега
create_annotated_tag() {
    local version="$1"
    local description="$2"
    
    # Получение информации о коммитах с последнего тега
    local last_tag=$(get_last_semver_tag)
    local commit_info=""
    
    if [ -n "$last_tag" ]; then
        commit_info=$(git log --oneline "$last_tag"..HEAD 2>/dev/null | head -n 10)
    else
        commit_info=$(git log --oneline -10 2>/dev/null)
    fi
    
    # Формирование сообщения тега
    local tag_message="$description

Дата: $(date +"%Y-%m-%d %H:%M:%S")
Коммиты:
$commit_info"

    # Создание тега
    if git tag -a "$version" -m "$tag_message"; then
        success "Тег '$version' создан"
        return 0
    else
        error "Не удалось создать тег '$version'"
        return 1
    fi
}

# Функция push тега
push_tag() {
    local version="$1"
    
    info "Отправка тега '$version' на удалённый репозиторий..."
    
    if git push origin "$version" 2>/dev/null; then
        success "Тег '$version' отправлен на удалённый репозиторий"
        return 0
    else
        warn "Не удалось отправить тег на удалённый репозиторий"
        info "Для отправки выполните: git push origin $version"
        return 1
    fi
}

# =============================================================================
# Основная логика
# =============================================================================

# Парсинг аргументов
for arg in "$@"; do
    case $arg in
        --help|-h)
            echo "Использование: $0 \"<version>\" \"<description>\""
            echo ""
            echo "Создание аннотированного тега версии"
            echo ""
            echo "Параметры:"
            echo "  version      Версия в формате semver (vX.Y.Z)"
            echo "  description  Описание релиза"
            echo ""
            echo "Примеры:"
            echo "  $0 \"v0.6.0\" \"Release v0.6.0: Feedback System\""
            echo "  $0 \"v1.0.0-beta.1\" \"Beta release\""
            exit 0
            ;;
    esac
done

# Проверка аргументов
if [ $# -lt 2 ]; then
    error "Недостаточно аргументов"
    echo ""
    echo "Использование:"
    echo "  $0 \"<version>\" \"<description>\""
    echo ""
    echo "Пример:"
    echo "  $0 \"v0.6.0\" \"Release v0.6.0: Feedback System\""
    exit 1
fi

VERSION="$1"
DESCRIPTION="$2"

# Проверка, что мы в git репозитории
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    error "Текущая директория не является git репозиторием"
    exit 1
fi

# Валидация версии
if ! validate_semver "$VERSION"; then
    exit 1
fi

# Нормализация версии
VERSION=$(normalize_version "$VERSION")

# Проверка существования тега
if git rev-parse "$VERSION" >/dev/null 2>&1; then
    error "Тег '$VERSION' уже существует"
    exit 1
fi

# Проверка текущей ветки
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)

if [ "$CURRENT_BRANCH" = "main" ]; then
    info "Создание релизного тега в ветке main"
elif [ "$CURRENT_BRANCH" = "develop" ] || [ "$CURRENT_BRANCH" = "dev" ]; then
    warn "Вы находитесь в ветке разработки '$CURRENT_BRANCH'"
    warn "Рекомендуется создавать теги в ветке main"
    echo ""
    read -p "Продолжить создание тега? (y/n): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        info "Отменено пользователем"
        exit 0
    fi
else
    warn "Вы находитесь в ветке '$CURRENT_BRANCH'"
    warn "Рекомендуется создавать теги в ветке main или release-ветке"
    echo ""
    read -p "Продолжить создание тега? (y/n): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        info "Отменено пользователем"
        exit 0
    fi
fi

# Проверка незакоммиченных изменений
if ! git diff-index --quiet HEAD --; then
    warn "Обнаружены незакоммиченные изменения"
    error "Сначала закоммитьте все изменения перед созданием тега"
    exit 1
fi

# Анализ завершенных фаз
info "Анализ завершенных фаз..."
PHASES_INFO=$(analyze_completed_phases)
info "Статистика: $PHASES_INFO"

# Создание тега
info "Создание аннотированного тега..."
if ! create_annotated_tag "$VERSION" "$DESCRIPTION"; then
    exit 1
fi

# Обновление CHANGELOG
info "Обновление CHANGELOG..."
update_changelog "$VERSION" "$DESCRIPTION"

# Push тега
echo ""
read -p "Отправить тег на удалённый репозиторий? (y/n): " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    push_tag "$VERSION"
fi

# Вывод имени созданного тега
echo "$VERSION"

success "Релиз '$VERSION' успешно создан!"

exit 0
