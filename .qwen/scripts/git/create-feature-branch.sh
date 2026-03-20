#!/bin/bash
# =============================================================================
# create-feature-branch.sh
# =============================================================================
# Назначение: Автоматическое создание feature-ветки от develop
# 
# Использование:
#   .qwen/scripts/git/create-feature-branch.sh "<task-name>"
#
# Пример:
#   .qwen/scripts/git/create-feature-branch.sh "my-new-feature"
#   # Создает: feature/my-new-feature от develop
#
# Выход:
#   Успех: имя созданной ветки (stdout)
#   Ошибка: код ошибки + сообщение (stderr)
#
# Требования:
#   - Git должен быть инициализирован
#   - Ветка develop должна существовать
#   - Имя ветки должно соответствовать шаблону
# =============================================================================

set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

# Функция валидации имени ветки
validate_branch_name() {
    local name="$1"
    
    # Проверка на пустое имя
    if [ -z "$name" ]; then
        error "Имя ветки не может быть пустым"
        return 1
    fi
    
    # Проверка на допустимые символы (только lowercase, цифры, дефисы, подчеркивания)
    if ! [[ "$name" =~ ^[a-z0-9_-]+$ ]]; then
        error "Имя ветки должно содержать только строчные буквы, цифры, дефисы и подчеркивания"
        error "Недопустимое имя: $name"
        return 1
    fi
    
    # Проверка на начинающиеся/кончающиеся дефисы или подчеркивания
    if [[ "$name" =~ ^[-_] ]] || [[ "$name" =~ [-_]$ ]]; then
        error "Имя ветки не должно начинаться или заканчиваться на дефис или подчеркивание"
        return 1
    fi
    
    # Проверка на двойные дефисы или подчеркивания
    if [[ "$name" =~ (--|__) ]]; then
        error "Имя ветки не должно содержать двойные дефисы или подчеркивания"
        return 1
    fi
    
    # Проверка длины
    if [ ${#name} -gt 50 ]; then
        error "Имя ветки слишком длинное (максимум 50 символов)"
        return 1
    fi
    
    return 0
}

# Функция проверки существования ветки
branch_exists() {
    local branch="$1"
    git show-ref --verify --quiet refs/heads/"$branch" 2>/dev/null
}

# Функция получения текущей ветки
get_current_branch() {
    git rev-parse --abbrev-ref HEAD
}

# Функция получения develop ветки
get_develop_branch() {
    # Проверяем наличие develop или dev
    if branch_exists "develop"; then
        echo "develop"
    elif branch_exists "dev"; then
        echo "dev"
    else
        echo ""
    fi
}

# =============================================================================
# Основная логика
# =============================================================================

# Парсинг аргументов
for arg in "$@"; do
    case $arg in
        --help|-h)
            echo "Использование: $0 \"<task-name>\""
            echo ""
            echo "Создание feature-ветки от develop"
            echo ""
            echo "Параметры:"
            echo "  task-name    Название задачи для имени ветки"
            echo ""
            echo "Примеры:"
            echo "  $0 \"my-new-feature\""
            echo "  $0 \"bugfix-login\""
            exit 0
            ;;
    esac
done

# Проверка аргументов
if [ $# -lt 1 ]; then
    error "Не указано имя задачи"
    echo ""
    echo "Использование:"
    echo "  $0 \"<task-name>\""
    echo ""
    echo "Пример:"
    echo "  $0 \"my-new-feature\""
    exit 1
fi

TASK_NAME="$1"

# Проверка, что мы в git репозитории
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    error "Текущая директория не является git репозиторием"
    exit 1
fi

# Валидация имени ветки
if ! validate_branch_name "$TASK_NAME"; then
    exit 1
fi

# Формирование имени feature-ветки
FEATURE_BRANCH="feature/${TASK_NAME}"

# Проверка существования ветки
if branch_exists "$FEATURE_BRANCH"; then
    error "Ветка '$FEATURE_BRANCH' уже существует"
    exit 1
fi

# Получение develop ветки
DEVELOP_BRANCH=$(get_develop_branch)

if [ -z "$DEVELOP_BRANCH" ]; then
    error "Ветка develop или dev не найдена. Создайте основную ветку для разработки."
    exit 1
fi

# Получение текущей ветки
CURRENT_BRANCH=$(get_current_branch)

info "Текущая ветка: $CURRENT_BRANCH"
info "Базовая ветка: $DEVELOP_BRANCH"
info "Создаваемая ветка: $FEATURE_BRANCH"

# Проверка текущей ветки
if [ "$CURRENT_BRANCH" = "main" ] || [ "$CURRENT_BRANCH" = "$DEVELOP_BRANCH" ]; then
    info "Нахождение в ветке $CURRENT_BRANCH - создание feature-ветки от $DEVELOP_BRANCH"
else
    warn "Вы находитесь в ветке '$CURRENT_BRANCH'"
    warn "Feature-ветки рекомендуется создавать от develop/dev"
    echo ""
    read -p "Продолжить создание ветки $FEATURE_BRANCH от $DEVELOP_BRANCH? (y/n): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        info "Отменено пользователем"
        exit 0
    fi
fi

# Проверка наличия незакоммиченных изменений
if ! git diff-index --quiet HEAD --; then
    warn "Обнаружены незакоммиченные изменения"
    echo ""
    read -p "Создать ветку без коммита изменений? (y/n): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        info "Отменено пользователем. Сначала закоммитьте или отмените изменения."
        exit 0
    fi
fi

# Создание ветки
info "Создание ветки $FEATURE_BRANCH от $DEVELOP_BRANCH..."

git fetch origin "$DEVELOP_BRANCH" 2>/dev/null || true

if ! git checkout -b "$FEATURE_BRANCH" "$DEVELOP_BRANCH"; then
    error "Не удалось создать ветку $FEATURE_BRANCH"
    exit 1
fi

# Попытка push новой ветки
info "Попытка push ветки на удалённый репозиторий..."
if git push -u origin "$FEATURE_BRANCH" 2>/dev/null; then
    success "Ветка '$FEATURE_BRANCH' создана и отправлена на удалённый репозиторий"
else
    warn "Не удалось отправить ветку на удалённый репозиторий"
    info "Ветка '$FEATURE_BRANCH' создана локально"
    info "Для отправки выполните: git push -u origin $FEATURE_BRANCH"
fi

# Вывод имени созданной ветки (для использования в скриптах)
echo "$FEATURE_BRANCH"

exit 0
