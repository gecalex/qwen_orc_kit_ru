#!/bin/bash
# =============================================================================
# check-workflow.sh
# =============================================================================
# Назначение: Проверка соблюдения git workflow
# 
# Использование:
#   .qwen/scripts/git/check-workflow.sh
#
# Выход:
#   - Статус workflow
#   - Рекомендации по улучшению
#   - Код возврата: 0 (OK), 1 (предупреждения), 2 (ошибки)
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

# Счетчики
ERRORS=0
WARNINGS=0
INFO_COUNT=0

# Функция вывода ошибок
error() {
    echo -e "${RED}❌ ОШИБКА:${NC} $1"
    ((ERRORS++))
}

# Функция вывода предупреждений
warn() {
    echo -e "${YELLOW}⚠️  ПРЕДУПРЕЖДЕНИЕ:${NC} $1"
    ((WARNINGS++))
}

# Функция вывода информации
info() {
    echo -e "${BLUE}ℹ️  ИНФО:${NC} $1"
    ((INFO_COUNT++))
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
}

# Функция вывода подсказки
tip() {
    echo -e "${MAGENTA}💡 СОВЕТ:${NC} $1"
}

# Функция проверки git репозитория
check_git_repo() {
    section "Проверка Git репозитория"
    
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        error "Текущая директория не является git репозиторием"
        return 1
    fi
    
    success "Git репозиторий инициализирован"
    return 0
}

# Функция проверки текущей ветки
check_current_branch() {
    section "Проверка текущей ветки"
    
    local current_branch=$(git rev-parse --abbrev-ref HEAD)
    info "Текущая ветка: $current_branch"
    
    # Проверка на main
    if [ "$current_branch" = "main" ]; then
        warn "Вы находитесь в ветке main"
        tip "Для разработки создайте feature-ветку от develop:"
        echo "    .qwen/scripts/git/create-feature-branch.sh \"<task-name>\""
    fi
    
    # Проверка на develop/dev
    if [ "$current_branch" = "develop" ] || [ "$current_branch" = "dev" ]; then
        info "Ветка разработки - корректное состояние"
    fi
    
    # Проверка на feature-ветку
    if [[ "$current_branch" =~ ^feature/ ]]; then
        success "Feature-ветка - корректное состояние для разработки"
    fi
    
    # Проверка на bugfix-ветку
    if [[ "$current_branch" =~ ^bugfix/ ]]; then
        success "Bugfix-ветка - корректное состояние для исправлений"
    fi
    
    # Проверка на hotfix-ветку
    if [[ "$current_branch" =~ ^hotfix/ ]]; then
        success "Hotfix-ветка - корректное состояние для критических исправлений"
    fi
    
    return 0
}

# Функция проверки незакоммиченных изменений
check_uncommitted_changes() {
    section "Проверка незакоммиченных изменений"
    
    local staged_count=$(git diff --cached --name-only 2>/dev/null | wc -l)
    local unstaged_count=$(git diff --name-only 2>/dev/null | wc -l)
    local untracked_count=$(git ls-files --others --exclude-standard 2>/dev/null | wc -l)
    
    info "Staged изменений: $staged_count"
    info "Unstaged изменений: $unstaged_count"
    info "Неотслеживаемых файлов: $untracked_count"
    
    if [ "$staged_count" -gt 0 ]; then
        warn "Есть staged изменения для коммита"
        echo ""
        echo "Staged файлы:"
        git diff --cached --name-only
        echo ""
        tip "Для коммита используйте:"
        echo "    .qwen/scripts/git/pre-commit-review.sh \"<message>\""
    fi
    
    if [ "$unstaged_count" -gt 0 ]; then
        warn "Есть unstaged изменения"
        echo ""
        echo "Измененные файлы:"
        git diff --name-only
        echo ""
        tip "Добавьте изменения и создайте коммит"
    fi
    
    if [ "$untracked_count" -gt 0 ]; then
        info "Есть неотслеживаемые файлы"
        echo ""
        echo "Неотслеживаемые файлы:"
        git ls-files --others --exclude-standard | head -n 10
        if [ "$untracked_count" -gt 10 ]; then
            echo "    ... и еще $((untracked_count - 10)) файлов"
        fi
        echo ""
        
        # Проверка на потенциальные секреты
        local secrets_found=0
        for file in $(git ls-files --others --exclude-standard); do
            if [[ "$file" =~ \.(env|key|pem|crt)$ ]] || [[ "$file" =~ secret ]]; then
                error "Потенциально чувствительный файл: $file"
                ((secrets_found++))
            fi
        done
        
        if [ "$secrets_found" -gt 0 ]; then
            error "Найдено $secrets_found потенциально чувствительных файлов!"
            tip "Добавьте эти файлы в .gitignore"
        fi
    fi
    
    if [ "$staged_count" -eq 0 ] && [ "$unstaged_count" -eq 0 ] && [ "$untracked_count" -eq 0 ]; then
        success "Нет незакоммиченных изменений"
    fi
    
    return 0
}

# Функция проверки синхронизации с remote
check_remote_sync() {
    section "Проверка синхронизации с remote"
    
    # Проверка наличия remote
    if ! git remote -v | grep -q origin; then
        error "Remote 'origin' не настроен"
        tip "Добавьте remote:"
        echo "    git remote add origin <url>"
        return 1
    fi
    
    success "Remote 'origin' настроен"
    
    local current_branch=$(git rev-parse --abbrev-ref HEAD)
    
    # Попытка fetch
    info "Проверка обновлений remote..."
    if git fetch origin 2>/dev/null; then
        success "Связь с remote установлена"
    else
        warn "Не удалось соединиться с remote"
        return 0
    fi
    
    # Проверка отставания
    local behind=$(git rev-list --count HEAD..origin/"$current_branch" 2>/dev/null || echo "0")
    local ahead=$(git rev-list --count origin/"$current_branch"..HEAD 2>/dev/null || echo "0")
    
    if [ "$behind" -gt 0 ]; then
        warn "Ветка отстает от remote на $behind коммитов"
        tip "Обновите ветку:"
        echo "    git pull origin $current_branch"
    else
        info "Ветка не отстает от remote"
    fi
    
    if [ "$ahead" -gt 0 ]; then
        warn "Ветка опережает remote на $ahead коммитов"
        tip "Отправьте изменения:"
        echo "    git push origin $current_branch"
    else
        info "Ветка синхронизирована с remote"
    fi
    
    return 0
}

# Функция проверки тегов
check_tags() {
    section "Проверка тегов"
    
    local tags_count=$(git tag | wc -l)
    info "Всего тегов: $tags_count"
    
    if [ "$tags_count" -eq 0 ]; then
        warn "В репозитории нет тегов"
        tip "Создайте первый тег после завершения фазы:"
        echo "    .qwen/scripts/git/auto-tag-release.sh \"v0.1.0\" \"Initial release\""
    else
        # Последние теги
        echo ""
        info "Последние 5 тегов:"
        git tag -l --sort=-v:refname | head -n 5
        
        # Проверка на последний semver тег
        local last_tag=$(git describe --tags --abbrev=0 2>/dev/null || echo "")
        if [ -n "$last_tag" ]; then
            info "Последний тег: $last_tag"
            
            # Количество коммитов с последнего тега
            local commits_since_tag=$(git rev-list --count "$last_tag"..HEAD 2>/dev/null || echo "0")
            if [ "$commits_since_tag" -gt 10 ]; then
                warn "С последнего тега $commits_since_tag коммитов"
                tip "Возможно, стоит создать новый тег"
            fi
        fi
    fi
    
    return 0
}

# Функция проверки структуры веток
check_branch_structure() {
    section "Проверка структуры веток"
    
    local branches=$(git branch -a)
    
    # Проверка наличия main/master
    if echo "$branches" | grep -qE '^\*?\s*(main|master)'; then
        success "Основная ветка (main/master) существует"
    else
        warn "Не найдена основная ветка (main/master)"
    fi
    
    # Проверка наличия develop/dev
    if echo "$branches" | grep -qE '^\*?\s*(develop|dev)'; then
        success "Ветка разработки (develop/dev) существует"
    else
        warn "Не найдена ветка разработки (develop/dev)"
        tip "Создайте ветку develop от main:"
        echo "    git checkout main"
        echo "    git checkout -b develop"
        echo "    git push -u origin develop"
    fi
    
    # Подсчет feature-веток
    local feature_count=$(echo "$branches" | grep -c 'feature/' || echo "0")
    info "Feature-веток: $feature_count"
    
    # Подсчет bugfix-веток
    local bugfix_count=$(echo "$branches" | grep -c 'bugfix/' || echo "0")
    info "Bugfix-веток: $bugfix_count"
    
    # Подсчет hotfix-веток
    local hotfix_count=$(echo "$branches" | grep -c 'hotfix/' || echo "0")
    info "Hotfix-веток: $hotfix_count"
    
    # Проверка на старые ветки
    local old_branches=$(git branch --sort=committerdate | head -n -5)
    if [ -n "$old_branches" ]; then
        info "Возможно, есть старые ветки для удаления"
    fi
    
    return 0
}

# Функция проверки .gitignore
check_gitignore() {
    section "Проверка .gitignore"
    
    if [ -f ".gitignore" ]; then
        success "Файл .gitignore существует"
        
        local ignore_count=$(wc -l < .gitignore)
        info "Правил игнорирования: $ignore_count"
        
        # Проверка на типичные записи
        local common_patterns=("node_modules" ".env" "*.log" ".DS_Store" "dist" "build")
        local missing_patterns=()
        
        for pattern in "${common_patterns[@]}"; do
            if ! grep -q "$pattern" .gitignore 2>/dev/null; then
                missing_patterns+=("$pattern")
            fi
        done
        
        if [ ${#missing_patterns[@]} -gt 0 ]; then
            warn "Отсутствуют типичные паттерны: ${missing_patterns[*]}"
        fi
    else
        error "Файл .gitignore отсутствует"
        tip "Создайте .gitignore для вашего проекта"
    fi
    
    return 0
}

# Функция вывода итогов
print_summary() {
    section "Итоги проверки"
    
    echo ""
    if [ "$ERRORS" -eq 0 ] && [ "$WARNINGS" -eq 0 ]; then
        success "Все проверки пройдены успешно!"
        echo ""
        echo "Ваш git workflow в отличном состоянии 🎉"
    elif [ "$ERRORS" -eq 0 ]; then
        warn "Обнаружено предупреждений: $WARNINGS"
        echo ""
        echo "Workflow работает, но есть рекомендации к улучшению"
    else
        error "Обнаружено ошибок: $ERRORS"
        warn "Обнаружено предупреждений: $WARNINGS"
        echo ""
        echo "Требуется внимание к указанным проблемам"
    fi
    
    echo ""
    echo "═══════════════════════════════════════════════════════════"
    echo "  Статистика"
    echo "═══════════════════════════════════════════════════════════"
    echo "  Ошибки:       $ERRORS"
    echo "  Предупреждения: $WARNINGS"
    echo "  Инфо:         $INFO_COUNT"
    echo "═══════════════════════════════════════════════════════════"
    echo ""
}

# Функция вывода рекомендаций
print_recommendations() {
    if [ "$ERRORS" -gt 0 ] || [ "$WARNINGS" -gt 0 ]; then
        section "Рекомендации"
        echo ""
        
        if [ "$ERRORS" -gt 0 ]; then
            echo -e "${RED}Критические действия:${NC}"
            echo "  1. Исправьте все ошибки перед продолжением работы"
            echo "  2. Проверьте чувствительные файлы в .gitignore"
            echo ""
        fi
        
        if [ "$WARNINGS" -gt 0 ]; then
            echo -e "${YELLOW}Рекомендуемые действия:${NC}"
            echo "  1. Создайте feature-ветку для новой задачи"
            echo "  2. Закоммитьте незавершенные изменения"
            echo "  3. Синхронизируйтесь с remote"
            echo "  4. Создайте тег после завершения фазы"
            echo ""
        fi
        
        echo -e "${BLUE}Полезные команды:${NC}"
        echo "  .qwen/scripts/git/create-feature-branch.sh \"<task>\"  - создать ветку"
        echo "  .qwen/scripts/git/pre-commit-review.sh \"<msg>\"       - коммит"
        echo "  .qwen/scripts/git/auto-tag-release.sh \"vX.Y.Z\" \"...\" - тег"
        echo ""
    fi
}

# =============================================================================
# Основная логика
# =============================================================================

echo ""
echo -e "${CYAN}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║         Git Workflow Checker - Qwen Orchestrator          ║${NC}"
echo -e "${CYAN}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""

# Запуск проверок
check_git_repo || { print_summary; exit 2; }
check_current_branch
check_uncommitted_changes
check_remote_sync
check_tags
check_branch_structure
check_gitignore

# Вывод итогов
print_summary
print_recommendations

# Код возврата
if [ "$ERRORS" -gt 0 ]; then
    exit 2
elif [ "$WARNINGS" -gt 0 ]; then
    exit 1
else
    exit 0
fi
