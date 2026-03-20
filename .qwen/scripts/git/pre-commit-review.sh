#!/bin/bash
# =============================================================================
# pre-commit-review.sh
# =============================================================================
# Назначение: Pre-commit ревью изменений
# 
# Использование:
#   .qwen/scripts/git/pre-commit-review.sh "<commit-message>"
#   .qwen/scripts/git/pre-commit-review.sh "<commit-message>" --no-interactive
#
# Пример:
#   .qwen/scripts/git/pre-commit-review.sh "feat: Add new feature"
#   .qwen/scripts/git/pre-commit-review.sh "feat: Add new feature" --no-interactive
#
# Функционал:
#   - Показать git status
#   - Показать git diff --stat
#   - Показать git diff (опционально)
#   - Запросить подтверждение
#   - Только после подтверждения → git add и git commit
#
# Требования:
#   - Интерактивный режим по умолчанию
#   - Поддержка --no-interactive для CI/CD
#   - Валидация сообщения коммита (Conventional Commits)
# =============================================================================

set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Флаги
INTERACTIVE=true
SHOW_FULL_DIFF=false

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

# Функция вывода раздела
section() {
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  $1${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo ""
}

# Функция валидации сообщения коммита (Conventional Commits)
validate_commit_message() {
    local message="$1"
    
    # Проверка на пустое сообщение
    if [ -z "$message" ]; then
        error "Сообщение коммита не может быть пустым"
        return 1
    fi
    
    # Паттерн Conventional Commits
    # type(scope): description
    # type: description
    local pattern="^(feat|fix|docs|style|refactor|test|chore|perf|ci|build|revert)(\([a-z0-9_-]+\))?: .+"
    
    if ! [[ "$message" =~ $pattern ]]; then
        warn "Сообщение не соответствует формату Conventional Commits"
        echo ""
        echo "Ожидаемый формат: type(scope): description"
        echo ""
        echo "Доступные типы:"
        echo "  feat     - Новая функция"
        echo "  fix      - Исправление ошибки"
        echo "  docs     - Изменения в документации"
        echo "  style    - Форматирование, отступы"
        echo "  refactor - Рефакторинг без изменений функциональности"
        echo "  test     - Добавление/изменение тестов"
        echo "  chore    - Служебные изменения"
        echo "  perf     - Улучшение производительности"
        echo "  ci       - Изменения в CI/CD"
        echo "  build    - Изменения в системе сборки"
        echo "  revert   - Отмена предыдущего коммита"
        echo ""
        echo "Примеры:"
        echo "  feat: добавлена аутентификация пользователя"
        echo "  fix(api): исправлена ошибка тайм-аута"
        echo "  docs: обновлена инструкция по установке"
        echo ""
        
        if [ "$INTERACTIVE" = true ]; then
            read -p "Продолжить с этим сообщением? (y/n): " -n 1 -r
            echo ""
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                return 1
            fi
        else
            # В неинтерактивном режиме предупреждаем, но продолжаем
            warn "Продолжаем с некорректным сообщением (CI/CD режим)"
        fi
    fi
    
    return 0
}

# Функция показа git status
show_status() {
    section "Git Status"
    git status --short
    echo ""
    
    local changed_files=$(git status --short | wc -l)
    info "Изменено файлов: $changed_files"
}

# Функция показа git diff --stat
show_diff_stat() {
    section "Изменения (diff --stat)"
    git diff --stat
    echo ""
    
    local insertions=$(git diff --stat | tail -1 | grep -oP '\d+(?= insertion)' || echo "0")
    local deletions=$(git diff --stat | tail -1 | grep -oP '\d+(?= deletion)' || echo "0")
    
    info "Вставлено строк: $insertions"
    info "Удалено строк: $deletions"
}

# Функция показа полного git diff
show_full_diff() {
    section "Полный diff"
    git diff --color=always
    echo ""
}

# Функция показа staged изменений
show_staged_changes() {
    section "Staged изменения"
    git diff --cached --stat
    echo ""
}

# Функция проверки Conventional Commits
check_commit_conventions() {
    local message="$1"
    
    # Извлечение типа коммита
    local commit_type=$(echo "$message" | grep -oP '^[a-z]+' || echo "")
    
    case "$commit_type" in
        feat)
            info "Тип коммита: FEAT (новая функция)"
            ;;
        fix)
            info "Тип коммита: FIX (исправлениe ошибки)"
            ;;
        docs)
            info "Тип коммита: DOCS (документация)"
            ;;
        refactor)
            info "Тип коммита: REFACTOR (рефакторинг)"
            ;;
        test)
            info "Тип коммита: TEST (тесты)"
            ;;
        chore)
            info "Тип коммита: CHORE (служебные изменения)"
            ;;
        *)
            warn "Неизвестный тип коммита: $commit_type"
            ;;
    esac
}

# =============================================================================
# Основная логика
# =============================================================================

# Парсинг аргументов
COMMIT_MESSAGE=""

for arg in "$@"; do
    case $arg in
        --no-interactive)
            INTERACTIVE=false
            ;;
        --full-diff)
            SHOW_FULL_DIFF=true
            ;;
        --help|-h)
            echo "Использование: $0 \"<commit-message>\" [опции]"
            echo ""
            echo "Опции:"
            echo "  --no-interactive  Неинтерактивный режим (для CI/CD)"
            echo "  --full-diff       Показать полный diff"
            echo "  --help, -h        Показать эту справку"
            echo ""
            echo "Примеры:"
            echo "  $0 \"feat: Add new feature\""
            echo "  $0 \"fix: Fix bug\" --no-interactive"
            exit 0
            ;;
        *)
            if [ -z "$COMMIT_MESSAGE" ]; then
                COMMIT_MESSAGE="$arg"
            fi
            ;;
    esac
done

# Проверка аргументов
if [ -z "$COMMIT_MESSAGE" ]; then
    error "Не указано сообщение коммита"
    echo ""
    echo "Использование:"
    echo "  $0 \"<commit-message>\" [опции]"
    echo ""
    echo "Пример:"
    echo "  $0 \"feat: Add new feature\""
    echo "  $0 \"feat: Add new feature\" --no-interactive"
    exit 1
fi

# Проверка, что мы в git репозитории
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    error "Текущая директория не является git репозиторием"
    exit 1
fi

# Валидация сообщения коммита
if ! validate_commit_message "$COMMIT_MESSAGE"; then
    error "Сообщение коммита не прошло валидацию"
    exit 1
fi

# Проверка наличия изменений
if git diff-index --quiet HEAD -- && [ -z "$(git ls-files --others --exclude-standard)" ]; then
    warn "Нет изменений для коммита"
    exit 0
fi

# Показ статуса и изменений
show_status
show_diff_stat

if [ "$SHOW_FULL_DIFF" = true ]; then
    show_full_diff
fi

# Проверка staged изменений
STAGED_COUNT=$(git diff --cached --name-only | wc -l)

if [ "$STAGED_COUNT" -gt 0 ]; then
    show_staged_changes
fi

# Валидация и подтверждение
section "Подтверждение коммита"

echo -e "${MAGENTA}Сообщение коммита:${NC}"
echo "  $COMMIT_MESSAGE"
echo ""

check_commit_conventions "$COMMIT_MESSAGE"

echo ""
echo -e "${CYAN}Файлы для коммита:${NC}"
git status --short
echo ""

if [ "$INTERACTIVE" = true ]; then
    # Интерактивный режим
    echo -e "${YELLOW}Внимание: После коммита изменения нельзя будет легко отменить!${NC}"
    echo ""
    read -p "Создать коммит? (y/n): " -n 1 -r
    echo ""
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        info "Отменено пользователем"
        exit 0
    fi
    
    # Дополнительная проверка для больших коммитов
    local changed_count=$(git status --short | wc -l)
    if [ "$changed_count" -gt 20 ]; then
        warn "Большой коммит: $changed_count файлов"
        echo ""
        echo "Рекомендуется разбить на несколько логических коммитов."
        echo ""
        read -p "Продолжить с большим коммитом? (y/n): " -n 1 -r
        echo ""
        
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            info "Отменено пользователем"
            exit 0
        fi
    fi
fi

# Добавление всех изменений
info "Добавление изменений в staging area..."
git add -A

# Создание коммита
info "Создание коммита..."

if git commit -m "$COMMIT_MESSAGE"; then
    success "Коммит успешно создан!"
    echo ""
    git log -1 --pretty=format:"%h - %s (%ad)" --date=short
    echo ""
else
    error "Не удалось создать коммит"
    exit 1
fi

# Предложение сделать push
if [ "$INTERACTIVE" = true ]; then
    echo ""
    read -p "Отправить изменения на удалённый репозиторий? (y/n): " -n 1 -r
    echo ""
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        info "Отправка изменений..."
        CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
        
        if git push -u origin "$CURRENT_BRANCH"; then
            success "Изменения отправлены на удалённый репозиторий"
        else
            warn "Не удалось отправить изменения"
        fi
    fi
fi

exit 0
