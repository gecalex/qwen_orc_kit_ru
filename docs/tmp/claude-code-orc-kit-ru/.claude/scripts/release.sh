#!/usr/bin/env bash
#
# Скрипт автоматизации релизов
# Автоматизированное управление релизами с увеличением версии и генерацией changelog
#
# Возможности:
# - Авто-синхронизация версий package.json с последним git-тегом (предотвращает конфликты версий)
# - Авто-определение увеличения версии из conventional коммитов
# - Генерация записей CHANGELOG.md в формате Keep a Changelog
# - Поддержка категорий безопасности, устаревания и удаления
# - Безопасный откат с резервными копиями файлов (без потерь данных при ошибках)
# - Поддержка отката для неудавшихся релизов
#
# Использование: ./release.sh [patch|minor|major] [--yes]
#        Оставьте пустым для автоопределения из conventional коммитов
#        --yes: Пропустить подтверждение (для автоматизации)
#
# Поддерживаемые типы conventional commit:
#   security:   → Раздел безопасности (patch версия)
#   feat:       → Раздел Added (minor версия)
#   fix:        → Раздел Fixed (patch версия)
#   deprecate:  → Раздел Deprecated
#   remove:     → Раздел Removed
#   refactor:   → Раздел Changed
#   perf:       → Раздел Changed
#   type!:      → Критические изменения (major версия)

set -euo pipefail

# === КОНФИГУРАЦИЯ ===
readonly DATE=$(date +%Y-%m-%d)
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Цвета для вывода
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # Без цвета

# Отслеживание состояния для отката
CREATED_COMMIT=""
CREATED_TAG=""
declare -a MODIFIED_FILES=()
declare -a BACKUP_FILES=()  # Отслеживание файлов резервных копий для безопасного отката

# Массивы категоризации коммитов
declare -a ALL_COMMITS=()
declare -a FEATURES=()
declare -a FIXES=()
declare -a BREAKING_CHANGES=()
declare -a REFACTORS=()
declare -a PERF=()
declare -a SECURITY_FIXES=()      # Исправления уязвимостей безопасности
declare -a DEPRECATIONS=()        # Устаревшие функции
declare -a REMOVALS=()            # Удалённые функции
declare -a OTHER_CHANGES=()

# === ФУНКЦИИ УТИЛИТ ===

log_info() {
    echo -e "${BLUE}ℹ️  $*${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $*${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $*${NC}"
}

log_error() {
    echo -e "${RED}❌ $*${NC}" >&2
}

# === РЕЗЕРВНОЕ КОПИРОВАНИЕ И ВОССТАНОВЛЕНИЕ ===

create_backup() {
    local file="$1"

    # Создавать резервную копию только если файл существует
    if [ ! -f "$file" ]; then
        return 0
    fi

    local backup="${file}.backup.$$"
    cp "$file" "$backup" || {
        log_error "Не удалось создать резервную копию $file"
        exit 1
    }

    BACKUP_FILES+=("$backup")
    log_info "Создана резервная копия: ${backup##*/}"
}

restore_from_backups() {
    if [ ${#BACKUP_FILES[@]} -eq 0 ]; then
        return 0
    fi

    log_info "Восстановление файлов из резервных копий..."

    for backup in "${BACKUP_FILES[@]}"; do
        # Извлечение оригинального имени файла путём удаления суффикса .backup.$$
        local original="${backup%.backup.*}"

        if [ -f "$backup" ]; then
            mv "$backup" "$original"
            log_success "Восстановлено: ${original##*/}"
        fi
    done
}

cleanup_backups() {
    # Очистка файлов резервных копий после успешного релиза
    for backup in "${BACKUP_FILES[@]}"; do
        if [ -f "$backup" ]; then
            rm -f "$backup"
        fi
    done
}

# === ОЧИСТКА И ОТКАТ ===

cleanup() {
    local exit_code=$?

    if [ $exit_code -ne 0 ]; then
        echo ""
        log_error "Произошла ошибка во время процесса релиза"
        echo ""
        log_warning "Откат изменений..."

        # Удалить тег если создан
        if [ -n "$CREATED_TAG" ]; then
            git tag -d "$CREATED_TAG" 2>/dev/null || true
            log_success "Удалён тег $CREATED_TAG"
        fi

        # Откат коммита с помощью reset --soft для сохранения рабочей директории
        if [ -n "$CREATED_COMMIT" ]; then
            git reset --soft HEAD~1 2>/dev/null || true
            log_success "Откат коммита (рабочая директория сохранена)"
        fi

        # БЕЗОПАСНЫЙ ОТКАТ: Восстановление из резервных копий вместо git restore
        # Это сохраняет любые ручные правки, сделанные до запуска скрипта
        restore_from_backups

        echo ""
        log_info "Откат завершён. Файлы восстановлены из резервных копий."
        echo ""
        exit $exit_code
    else
        # Успех - очистка файлов резервных копий
        cleanup_backups
    fi
}

trap cleanup EXIT

# === ПРЕДВАРИТЕЛЬНЫЕ ПРОВЕРКИ ===

run_preflight_checks() {
    log_info "Выполнение предварительных проверок..."
    echo ""

    # Проверка, что мы в корне проекта
    if [ ! -f "$PROJECT_ROOT/package.json" ]; then
        log_error "Не в корне проекта. Не удалось найти package.json"
        exit 1
    fi

    # Проверка, что находимся на ветке (не отсоединённый HEAD)
    BRANCH=$(git branch --show-current)
    if [ -z "$BRANCH" ]; then
        log_error "Вы находитесь в состоянии отсоединённого HEAD"
        echo "Сначала переключитесь на ветку:"
        echo "  git checkout main"
        exit 1
    fi
    log_success "На ветке: $BRANCH"

    # Авто-коммит незафиксированных изменений перед релизом
    if ! git diff-index --quiet HEAD -- 2>/dev/null; then
        log_info "Обнаружены незафиксированные изменения. Авто-фиксация перед релизом..."

        # Получение количества файлов по статусу
        MODIFIED_COUNT=$(git diff --name-only | wc -l)
        STAGED_COUNT=$(git diff --cached --name-only | wc -l)
        UNTRACKED_COUNT=$(git ls-files --others --exclude-standard | wc -l)
        TOTAL_COUNT=$((MODIFIED_COUNT + STAGED_COUNT + UNTRACKED_COUNT))

        # Добавление ВСЕХ изменений (модифицированные, удалённые, новые файлы)
        git add -A

        # Получение подробного списка файлов для тела коммита
        FILE_LIST=$(git diff --cached --name-status | sed 's/^/  /')

        # Определение типа коммита на основе изменённых файлов
        local commit_type="chore"
        local commit_scope=""
        local commit_desc="обновление файлов проекта"

        # Получение изменений файлов со статусом (A=добавлен, M=модифицирован, D=удалён)
        local file_status=$(git diff --cached --name-status)

        # Подсчёт различных типов изменений
        local new_agents=$(echo "$file_status" | grep "^A.*\.claude/agents/.*\.md$" | wc -l)
        local new_skills=$(echo "$file_status" | grep "^A.*\.claude/skills/.*/SKILL\.md$" | wc -l)
        local new_commands=$(echo "$file_status" | grep "^A.*\.claude/commands/.*\.md$" | wc -l)
        local modified_agents=$(echo "$file_status" | grep "^M.*\.claude/agents/.*\.md$" | wc -l)
        local modified_scripts=$(echo "$file_status" | grep "^M.*\.claude/scripts/.*\.sh$" | wc -l)
        local modified_skills=$(echo "$file_status" | grep "^M.*\.claude/skills/.*/SKILL\.md$" | wc -l)
        local modified_commands=$(echo "$file_status" | grep "^M.*\.claude/commands/.*\.md$" | wc -l)
        local modified_docs=$(echo "$file_status" | grep "\.md$" | grep -v "\.claude/" | wc -l)
        local modified_mcp=$(echo "$file_status" | grep "mcp/.*\.json$" | wc -l)

        # Приоритетное определение типа коммита (самое специфичное первым)

        # 1. Новые агенты (наивысший приоритет для фич)
        if [ "$new_agents" -gt 0 ]; then
            commit_type="feat"
            commit_scope="agents"
            local agent_file=$(echo "$file_status" | grep "^A.*\.claude/agents/.*\.md$" | head -1 | awk '{print $2}')
            local agent_name=$(basename "$agent_file" .md)
            if [ "$new_agents" -eq 1 ]; then
                commit_desc="добавление агента ${agent_name}"
            else
                commit_desc="добавление ${new_agents} новых агентов (${agent_name}, ...)"
            fi

        # 2. Новые навыки
        elif [ "$new_skills" -gt 0 ]; then
            commit_type="feat"
            commit_scope="skills"
            local skill_file=$(echo "$file_status" | grep "^A.*\.claude/skills/.*/SKILL\.md$" | head -1 | awk '{print $2}')
            local skill_name=$(echo "$skill_file" | cut -d'/' -f4)
            if [ "$new_skills" -eq 1 ]; then
                commit_desc="добавление навыка ${skill_name}"
            else
                commit_desc="добавление ${new_skills} новых навыков (${skill_name}, ...)"
            fi

        # 3. Новые команды
        elif [ "$new_commands" -gt 0 ]; then
            commit_type="feat"
            commit_scope="commands"
            local cmd_file=$(echo "$file_status" | grep "^A.*\.claude/commands/.*\.md$" | head -1 | awk '{print $2}')
            local cmd_name=$(basename "$cmd_file" .md)
            if [ "$new_commands" -eq 1 ]; then
                commit_desc="добавление команды ${cmd_name}"
            else
                commit_desc="добавление ${new_commands} новых команд"
            fi

        # 4. Модифицированные навыки (фичи)
        elif [ "$modified_skills" -gt 0 ]; then
            commit_type="feat"
            commit_scope="skills"
            commit_desc="обновление реализаций навыков"

        # 5. Модифицированные команды (фичи)
        elif [ "$modified_commands" -gt 0 ]; then
            commit_type="feat"
            commit_scope="commands"
            commit_desc="обновление slash-команд"

        # 6. Модифицированные скрипты (chore)
        elif [ "$modified_scripts" -gt 0 ]; then
            commit_type="chore"
            commit_scope="scripts"
            commit_desc="обновление скриптов автоматизации"

        # 7. Модифицированные агенты (chore)
        elif [ "$modified_agents" -gt 0 ]; then
            commit_type="chore"
            commit_scope="agents"
            commit_desc="обновление конфигураций агентов"

        # 8. Модифицированные MCP-конфиги (chore)
        elif [ "$modified_mcp" -gt 0 ]; then
            commit_type="chore"
            commit_scope="mcp"
            commit_desc="обновление конфигураций MCP-серверов"

        # 9. Изменения документации
        elif [ "$modified_docs" -gt 0 ]; then
            commit_type="docs"
            commit_desc="обновление документации"
        fi

        # Генерация сообщения коммита с определённым типом
        if [ -n "$commit_scope" ]; then
            COMMIT_MSG="${commit_type}(${commit_scope}): ${commit_desc}"
        else
            COMMIT_MSG="${commit_type}: ${commit_desc}"
        fi

        COMMIT_MSG="${COMMIT_MSG}

Авто-зафиксировано ${TOTAL_COUNT} файл(ов) перед созданием релиза.

Файлы изменены:
${FILE_LIST}

🤖 Сгенерировано с помощью [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"

        # Создание коммита
        git commit -m "$COMMIT_MSG" >/dev/null 2>&1 || {
            log_error "Не удалось авто-зафиксировать изменения"
            exit 1
        }

        log_success "Изменения зафиксированы (${TOTAL_COUNT} файлов)"
        log_info "Тип коммита: ${commit_type}${commit_scope:+(${commit_scope})}: ${commit_desc}"
    fi

    # Проверка, что удалённый репозиторий настроен
    if ! git remote -v | grep -q origin; then
        log_error "Удалённый репозиторий 'origin' не настроен"
        exit 1
    fi
    log_success "Удалённый репозиторий настроен"

    # Проверка Node.js
    if ! command -v node &> /dev/null; then
        log_error "Node.js не установлен"
        exit 1
    fi
    log_success "Node.js доступен"

    # Получение текущей версии
    CURRENT_VERSION=$(node -p "require('$PROJECT_ROOT/package.json').version")
    if [ -z "$CURRENT_VERSION" ]; then
        log_error "Не удалось прочитать текущую версию из package.json"
        exit 1
    fi
    log_success "Текущая версия: $CURRENT_VERSION"

    # Получение последнего git-тега (по всем веткам с помощью --all)
    LAST_TAG=$(git tag --sort=-version:refname | head -n 1 || echo "")
    if [ -z "$LAST_TAG" ]; then
        log_warning "Предыдущие git-теги не найдены (первый релиз)"
        LAST_TAG="HEAD~999999" # Получить все коммиты
        COMMITS_RANGE="HEAD"
    else
        log_success "Последний тег: $LAST_TAG"
        COMMITS_RANGE="${LAST_TAG}..HEAD"

        # Синхронизация версии package.json с git-тегом при необходимости
        TAG_VERSION="${LAST_TAG#v}" # Удалить префикс 'v'
        if [ "$CURRENT_VERSION" != "$TAG_VERSION" ]; then
            log_warning "Несоответствие версий: package.json ($CURRENT_VERSION) != тег ($TAG_VERSION)"
            log_info "Синхронизация версий package.json с $TAG_VERSION..."

            # Найти и обновить все файлы package.json
            find "$PROJECT_ROOT" -name "package.json" -not -path "*/node_modules/*" -print0 | while IFS= read -r -d '' pkg_file; do
                if grep -q "\"version\"" "$pkg_file"; then
                    sed -i "s/\"version\": \"[^\"]*\"/\"version\": \"$TAG_VERSION\"/" "$pkg_file"
                    MODIFIED_FILES+=("$pkg_file")
                fi
            done

            CURRENT_VERSION="$TAG_VERSION"
            log_success "Синхронизированы все файлы package.json с версией $TAG_VERSION"
        fi
    fi

    # Проверка коммитов с последнего тега
    COMMITS_COUNT=$(git rev-list $COMMITS_RANGE --count 2>/dev/null || echo "0")
    if [ "$COMMITS_COUNT" -eq 0 ]; then
        log_error "Нет коммитов с последнего релиза ($LAST_TAG)"
        echo "Нечего релизить!"
        exit 1
    fi
    log_success "Найдено $COMMITS_COUNT коммитов с последнего релиза"

    echo ""
}

# === COMMIT PARSING ===

parse_commits() {
    log_info "Analyzing commits since ${LAST_TAG:-start}..."
    echo ""

    # Get all commits with hash
    while IFS= read -r line; do
        if [ -n "$line" ]; then
            ALL_COMMITS+=("$line")
        fi
    done < <(git log --format="%h %s" $COMMITS_RANGE)

    # Parse and categorize each commit
    # Define regex patterns as variables for proper bash regex matching
    local breaking_pattern='^[a-z]+(\([^)]+\))?!:'
    local feat_pattern='^feat(\([^)]+\))?:'
    local fix_pattern='^fix(\([^)]+\))?:'
    local refactor_pattern='^refactor(\([^)]+\))?:'
    local perf_pattern='^perf(\([^)]+\))?:'
    local security_pattern='^security(\([^)]+\))?:'
    local deprecate_pattern='^deprecate(\([^)]+\))?:'
    local remove_pattern='^remove(\([^)]+\))?:'

    for commit in "${ALL_COMMITS[@]}"; do
        local hash=$(echo "$commit" | awk '{print $1}')
        local message=$(echo "$commit" | cut -d' ' -f2-)

        # Check for breaking changes
        if [[ "$message" =~ $breaking_pattern ]] || echo "$message" | grep -q "BREAKING CHANGE:"; then
            BREAKING_CHANGES+=("$commit")
        # Check for security fixes (high priority!)
        elif [[ "$message" =~ $security_pattern ]]; then
            SECURITY_FIXES+=("$commit")
        # Check for features
        elif [[ "$message" =~ $feat_pattern ]]; then
            FEATURES+=("$commit")
        # Check for fixes
        elif [[ "$message" =~ $fix_pattern ]]; then
            FIXES+=("$commit")
        # Check for deprecations
        elif [[ "$message" =~ $deprecate_pattern ]]; then
            DEPRECATIONS+=("$commit")
        # Check for removals
        elif [[ "$message" =~ $remove_pattern ]]; then
            REMOVALS+=("$commit")
        # Check for refactors
        elif [[ "$message" =~ $refactor_pattern ]]; then
            REFACTORS+=("$commit")
        # Check for performance improvements
        elif [[ "$message" =~ $perf_pattern ]]; then
            PERF+=("$commit")
        # Everything else
        else
            OTHER_CHANGES+=("$commit")
        fi
    done

    # Display commit summary
    log_info "Commit summary:"
    [ ${#BREAKING_CHANGES[@]} -gt 0 ] && echo "  🔥 ${#BREAKING_CHANGES[@]} breaking changes"
    [ ${#SECURITY_FIXES[@]} -gt 0 ] && echo "  🔒 ${#SECURITY_FIXES[@]} security fixes"
    [ ${#FEATURES[@]} -gt 0 ] && echo "  ✨ ${#FEATURES[@]} features"
    [ ${#FIXES[@]} -gt 0 ] && echo "  🐛 ${#FIXES[@]} bug fixes"
    [ ${#DEPRECATIONS[@]} -gt 0 ] && echo "  ⚠️  ${#DEPRECATIONS[@]} deprecations"
    [ ${#REMOVALS[@]} -gt 0 ] && echo "  🗑️  ${#REMOVALS[@]} removals"
    [ ${#REFACTORS[@]} -gt 0 ] && echo "  ♻️  ${#REFACTORS[@]} refactors"
    [ ${#PERF[@]} -gt 0 ] && echo "  ⚡ ${#PERF[@]} performance improvements"
    [ ${#OTHER_CHANGES[@]} -gt 0 ] && echo "  📝 ${#OTHER_CHANGES[@]} other changes"
    echo ""
}

# === VERSION BUMP DETECTION ===

detect_version_bump() {
    local provided_bump="$1"

    # If bump type provided, validate and use it
    if [ -n "$provided_bump" ]; then
        if [[ ! "$provided_bump" =~ ^(patch|minor|major)$ ]]; then
            log_error "Invalid version bump type: $provided_bump"
            echo "Usage: ./release.sh [patch|minor|major]"
            exit 1
        fi
        BUMP_TYPE="$provided_bump"
        AUTO_DETECT_REASON="Manually specified"
        log_info "Using manual version bump: $BUMP_TYPE"
    else
        # Auto-detect from commits
        if [ ${#BREAKING_CHANGES[@]} -gt 0 ]; then
            BUMP_TYPE="major"
            AUTO_DETECT_REASON="Found ${#BREAKING_CHANGES[@]} breaking change(s)"
        elif [ ${#FEATURES[@]} -gt 0 ]; then
            BUMP_TYPE="minor"
            AUTO_DETECT_REASON="Found ${#FEATURES[@]} new feature(s)"
        elif [ ${#SECURITY_FIXES[@]} -gt 0 ]; then
            BUMP_TYPE="patch"
            AUTO_DETECT_REASON="Found ${#SECURITY_FIXES[@]} security fix(es)"
        elif [ ${#FIXES[@]} -gt 0 ]; then
            BUMP_TYPE="patch"
            AUTO_DETECT_REASON="Found ${#FIXES[@]} bug fix(es)"
        else
            BUMP_TYPE="patch"
            AUTO_DETECT_REASON="Default (no conventional commits detected)"
        fi
        log_success "Auto-detected version bump: $BUMP_TYPE ($AUTO_DETECT_REASON)"
    fi
    echo ""
}

# === VERSION CALCULATION ===

calculate_new_version() {
    local current="$CURRENT_VERSION"
    local IFS='.'
    read -ra parts <<< "$current"

    local major="${parts[0]}"
    local minor="${parts[1]}"
    local patch="${parts[2]}"

    case "$BUMP_TYPE" in
        major)
            major=$((major + 1))
            minor=0
            patch=0
            ;;
        minor)
            minor=$((minor + 1))
            patch=0
            ;;
        patch)
            patch=$((patch + 1))
            ;;
    esac

    NEW_VERSION="$major.$minor.$patch"
}

# === CHANGELOG GENERATION ===

generate_changelog_entry() {
    local version="$1"
    local date="$2"

    cat << EOF
## [$version] - $date

EOF

    # Security section (FIRST - highest priority!)
    if [ ${#SECURITY_FIXES[@]} -gt 0 ]; then
        echo "### Security"
        for commit in "${SECURITY_FIXES[@]}"; do
            format_changelog_line "$commit"
        done
        echo ""
    fi

    # Added section (features)
    if [ ${#FEATURES[@]} -gt 0 ]; then
        echo "### Added"
        for commit in "${FEATURES[@]}"; do
            format_changelog_line "$commit"
        done
        echo ""
    fi

    # Changed section (breaking, refactor, perf)
    if [ ${#BREAKING_CHANGES[@]} -gt 0 ] || [ ${#REFACTORS[@]} -gt 0 ] || [ ${#PERF[@]} -gt 0 ]; then
        echo "### Changed"
        for commit in "${BREAKING_CHANGES[@]}"; do
            format_changelog_line "$commit" "⚠️ BREAKING: "
        done
        for commit in "${REFACTORS[@]}"; do
            format_changelog_line "$commit"
        done
        for commit in "${PERF[@]}"; do
            format_changelog_line "$commit"
        done
        echo ""
    fi

    # Deprecated section
    if [ ${#DEPRECATIONS[@]} -gt 0 ]; then
        echo "### Deprecated"
        for commit in "${DEPRECATIONS[@]}"; do
            format_changelog_line "$commit"
        done
        echo ""
    fi

    # Removed section
    if [ ${#REMOVALS[@]} -gt 0 ]; then
        echo "### Removed"
        for commit in "${REMOVALS[@]}"; do
            format_changelog_line "$commit"
        done
        echo ""
    fi

    # Fixed section
    if [ ${#FIXES[@]} -gt 0 ]; then
        echo "### Fixed"
        for commit in "${FIXES[@]}"; do
            format_changelog_line "$commit"
        done
        echo ""
    fi
}

format_changelog_line() {
    local commit="$1"
    local prefix="${2:-}"

    local hash=$(echo "$commit" | awk '{print $1}')
    local message=$(echo "$commit" | cut -d' ' -f2-)

    # Extract scope if present: "type(scope): message" -> "**scope**: message"
    local scope_pattern='^[a-z]+(\(([^)]+)\))?!?:[ ]+(.+)$'
    if [[ "$message" =~ $scope_pattern ]]; then
        local scope="${BASH_REMATCH[2]}"
        local msg="${BASH_REMATCH[3]}"

        if [ -n "$scope" ]; then
            echo "- ${prefix}**${scope}**: ${msg} (${hash})"
        else
            echo "- ${prefix}${msg} (${hash})"
        fi
    else
        # Not a conventional commit, use as-is
        echo "- ${prefix}${message} (${hash})"
    fi
}

# === PACKAGE.JSON UPDATES ===

update_package_files() {
    local version="$1"

    log_info "Updating package.json files..."
    echo ""

    # Find all package.json files
    local package_files=$(find "$PROJECT_ROOT" -name "package.json" \
        -not -path "*/node_modules/*" \
        -not -path "*/.next/*" \
        -not -path "*/dist/*" \
        -not -path "*/.turbo/*" \
        -not -path "*/build/*")

    while IFS= read -r pkg; do
        if [ -n "$pkg" ]; then
            # Create backup BEFORE modifying
            create_backup "$pkg"

            # Track for rollback
            MODIFIED_FILES+=("$pkg")

            # Update version using Node.js for proper JSON handling
            node -e "
                const fs = require('fs');
                const path = '$pkg';
                const data = JSON.parse(fs.readFileSync(path, 'utf-8'));
                data.version = '$version';
                fs.writeFileSync(path, JSON.stringify(data, null, 2) + '\n');
            " || {
                log_error "Failed to update $pkg"
                exit 1
            }

            # Show relative path
            local rel_path="${pkg#$PROJECT_ROOT/}"
            echo "  ✓ $rel_path"
        fi
    done <<< "$package_files"

    echo ""
}

# === CHANGELOG UPDATE ===

update_changelog() {
    local version="$1"
    local date="$2"

    log_info "Updating CHANGELOG.md..."

    local changelog_file="$PROJECT_ROOT/CHANGELOG.md"

    # Create backup BEFORE modifying
    create_backup "$changelog_file"

    # Track for rollback
    MODIFIED_FILES+=("$changelog_file")

    # Generate new entry
    local new_entry=$(generate_changelog_entry "$version" "$date")

    # Read existing changelog
    if [ -f "$changelog_file" ]; then
        local existing_content=$(<"$changelog_file")

        # Insert new entry after [Unreleased] section
        if echo "$existing_content" | grep -q "## \[Unreleased\]"; then
            # Find the line number of [Unreleased]
            local unreleased_line=$(echo "$existing_content" | grep -n "## \[Unreleased\]" | head -1 | cut -d: -f1)

            # Insert after [Unreleased] and its blank line
            {
                echo "$existing_content" | head -n $((unreleased_line))
                echo ""
                echo "$new_entry"
                echo "$existing_content" | tail -n +$((unreleased_line + 1))
            } > "$changelog_file"
        else
            # No [Unreleased] section, insert at the beginning after header
            {
                echo "$existing_content" | head -n 6
                echo ""
                echo "$new_entry"
                echo "$existing_content" | tail -n +7
            } > "$changelog_file"
        fi
    else
        # Create new CHANGELOG.md
        cat > "$changelog_file" << EOF
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

$new_entry
EOF
    fi

    log_success "CHANGELOG.md updated"
    echo ""
}

# === ПРЕДВАРИТЕЛЬНЫЙ ПРОСМОТР ===

show_preview() {
    cat << EOF
═══════════════════════════════════════════════════════════
                    ПРЕДВАРИТЕЛЬНЫЙ ПРОСМОТР РЕЛИЗА
═══════════════════════════════════════════════════════════

📌 Версия: $CURRENT_VERSION → $NEW_VERSION (${BUMP_TYPE^^})
   Причина: $AUTO_DETECT_REASON

📊 Включённые коммиты: ${#ALL_COMMITS[@]}
EOF

    [ ${#BREAKING_CHANGES[@]} -gt 0 ] && echo "   🔥 ${#BREAKING_CHANGES[@]} критических изменений"
    [ ${#SECURITY_FIXES[@]} -gt 0 ] && echo "   🔒 ${#SECURITY_FIXES[@]} исправлений безопасности"
    [ ${#FEATURES[@]} -gt 0 ] && echo "   ✨ ${#FEATURES[@]} фич"
    [ ${#FIXES[@]} -gt 0 ] && echo "   🐛 ${#FIXES[@]} исправлений багов"
    [ ${#DEPRECATIONS[@]} -gt 0 ] && echo "   ⚠️  ${#DEPRECATIONS[@]} устареваний"
    [ ${#REMOVALS[@]} -gt 0 ] && echo "   🗑️  ${#REMOVALS[@]} удалений"
    [ ${#REFACTORS[@]} -gt 0 ] && echo "   ♻️  ${#REFACTORS[@]} рефакторингов"
    [ ${#PERF[@]} -gt 0 ] && echo "   ⚡ ${#PERF[@]} улучшений производительности"
    [ ${#OTHER_CHANGES[@]} -gt 0 ] && echo "   📝 ${#OTHER_CHANGES[@]} других изменений"

    cat << EOF

📦 Обновления пакетов:
EOF

    find "$PROJECT_ROOT" -name "package.json" \
        -not -path "*/node_modules/*" \
        -not -path "*/.next/*" \
        -not -path "*/dist/*" \
        -not -path "*/.turbo/*" \
        -not -path "*/build/*" | while read -r pkg; do
        local rel_path="${pkg#$PROJECT_ROOT/}"
        echo "  ✓ $rel_path"
    done

    cat << EOF

📄 Запись CHANGELOG.md:
───────────────────────────────────────────────────────────
$(generate_changelog_entry "$NEW_VERSION" "$DATE")───────────────────────────────────────────────────────────

💬 Сообщение Git-коммита:
───────────────────────────────────────────────────────────
chore(release): v$NEW_VERSION

Релиз версии $NEW_VERSION с ${#FEATURES[@]} фичами и ${#FIXES[@]} исправлениями

Включает коммиты от ${LAST_TAG:-начала} до HEAD

🤖 Сгенерировано с помощью [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
───────────────────────────────────────────────────────────

🏷️  Git-тег: v$NEW_VERSION
🌿 Ветка: $BRANCH

═══════════════════════════════════════════════════════════
EOF
}

# === ПОДТВЕРЖДЕНИЕ ПОЛЬЗОВАТЕЛЯ ===

get_user_confirmation() {
    local auto_confirm="$1"

    echo ""

    # Пропустить подтверждение если флаг --yes указан
    if [ "$auto_confirm" = "true" ]; then
        log_info "Авто-подтверждение релиза (флаг --yes указан)"
        echo ""
        return 0
    fi

    read -p "Продолжить релиз? [Y/n]: " confirm

    if [[ ! "$confirm" =~ ^[Yy]?$ ]]; then
        log_warning "Релиз отменён пользователем"
        exit 0
    fi

    echo ""
}

# === ВЫПОЛНЕНИЕ РЕЛИЗА ===

execute_release() {
    log_info "Выполнение релиза..."
    echo ""

    # Очистка файлов резервных копий ПЕРЕД индексацией
    cleanup_backups

    # Индексация всех изменений
    log_info "Индексация изменений..."
    git add -A

    # Создание коммита
    log_info "Создание коммита релиза..."
    git commit -m "chore(release): v$NEW_VERSION

Релиз версии $NEW_VERSION с ${#FEATURES[@]} фичами и ${#FIXES[@]} исправлениями

Включает коммиты от ${LAST_TAG:-начала} до HEAD

🤖 Сгенерировано с помощью [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>" || {
        log_error "Не удалось создать коммит"
        exit 1
    }
    CREATED_COMMIT="true"
    log_success "Коммит создан"

    # Создание тега (сначала проверить существует ли)
    log_info "Создание git-тега..."

    # Проверить существует ли тег
    if git rev-parse "v$NEW_VERSION" >/dev/null 2>&1; then
        log_error "Тег v$NEW_VERSION уже существует!"
        echo ""
        log_info "Существующие теги:"
        git tag --sort=-version:refname | head -n 10
        echo ""
        log_info "Предлагаемые действия:"
        echo "  1. Удалить существующий тег: git tag -d v$NEW_VERSION && git push origin :refs/tags/v$NEW_VERSION"
        echo "  2. Использовать другую версию: ./release.sh [patch|minor|major]"
        exit 1
    fi

    local tag_message="Релиз v$NEW_VERSION

$(generate_changelog_entry "$NEW_VERSION" "$DATE")"

    git tag -a "v$NEW_VERSION" -m "$tag_message" || {
        log_error "Не удалось создать тег"
        exit 1
    }
    CREATED_TAG="v$NEW_VERSION"
    log_success "Тег v$NEW_VERSION создан"

    # Отправка на удалённый репозиторий
    log_info "Отправка на удалённый репозиторий..."
    git push origin "$BRANCH" --follow-tags || {
        log_error "Не удалось отправить на удалённый репозиторий"
        echo ""
        log_warning "Ваши изменения зафиксированы локально, но отправка не удалась."
        echo ""
        echo "Для повторной отправки:"
        echo "  git push origin $BRANCH --follow-tags"
        echo ""
        echo "Для отката:"
        echo "  git reset --hard HEAD~1"
        echo "  git tag -d v$NEW_VERSION"
        echo ""
        exit 1
    }
    log_success "Отправлено в origin/$BRANCH"

    echo ""
}

# === ГЛАВНАЯ ===

main() {
    cd "$PROJECT_ROOT"

    echo ""
    echo "╔═══════════════════════════════════════════════════════════╗"
    echo "║                    Автоматизация релизов                   ║"
    echo "╚═══════════════════════════════════════════════════════════╝"
    echo ""

    # Парсинг аргументов
    local bump_arg=""
    local auto_confirm="false"

    for arg in "$@"; do
        case "$arg" in
            --yes|-y)
                auto_confirm="true"
                ;;
            patch|minor|major)
                bump_arg="$arg"
                ;;
            *)
                log_error "Неизвестный аргумент: $arg"
                echo "Использование: $0 [patch|minor|major] [--yes]"
                exit 1
                ;;
        esac
    done

    # Запуск рабочего процесса
    run_preflight_checks
    parse_commits
    detect_version_bump "$bump_arg"
    calculate_new_version

    # Показать предварительный просмотр
    show_preview
    get_user_confirmation "$auto_confirm"

    # Выполнить релиз
    update_package_files "$NEW_VERSION"
    update_changelog "$NEW_VERSION" "$DATE"
    execute_release

    echo ""
    echo "╔═══════════════════════════════════════════════════════════╗"
    echo "║              РЕЛИЗ УСПЕШНО ВЫПОЛНЕН! 🎉                   ║"
    echo "╚═══════════════════════════════════════════════════════════╝"
    echo ""
    log_success "Выпущен v$NEW_VERSION"
    log_success "Тег: v$NEW_VERSION"
    log_success "Ветка: $BRANCH"
    echo ""
    log_info "Следующие шаги:"
    echo "  • Проверить релиз на GitHub: git remote -v"
    echo "  • Создать GitHub Release из тега (опционально)"
    echo "  • Уведомить команду если применимо"
    echo ""
}

# Запуск главной функции
main "$@"
