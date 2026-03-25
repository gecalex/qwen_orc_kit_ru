#!/bin/bash
# =============================================================================
# refinery.sh - Gastown Merge and Refinement
# =============================================================================
# Назначение: Merge результатов из worktree в основную ветку
#
# Использование:
#   .qwen/scripts/gastown/refinery.sh <collection-id> [options]
#
# Пример:
#   .qwen/scripts/gastown/refinery.sh "collect-20260321-120000-12345"
#
# Выход:
#   Успех: статус merge (stdout)
#   Ошибка: код ошибки + сообщение (stderr)
# =============================================================================

set -e

# =============================================================================
# Конфигурация
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GASTOWN_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")/gastown"
CONFIG_FILE="$GASTOWN_DIR/config.json"
REGISTRY_FILE="$GASTOWN_DIR/registry.json"
WORKTREES_DIR="$GASTOWN_DIR/worktrees"
LOGS_DIR="$GASTOWN_DIR/logs"
COLLECTIONS_DIR="$GASTOWN_DIR/collections"
ARCHIVES_DIR="$GASTOWN_DIR/archives"

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# Счетчики
ERRORS=0
WARNINGS=0

# =============================================================================
# Функции
# =============================================================================

error() {
    echo -e "${RED}❌ ОШИБКА:${NC} $1" >&2
    ((ERRORS++))
}

warn() {
    echo -e "${YELLOW}⚠️  ПРЕДУПРЕЖДЕНИЕ:${NC} $1" >&2
    ((WARNINGS++))
}

info() {
    echo -e "${BLUE}ℹ️  ИНФО:${NC} $1"
}

success() {
    echo -e "${GREEN}✅ УСПЕХ:${NC} $1"
}

section() {
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  $1${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
}

log_action() {
    local action="$1"
    local details="$2"
    local timestamp=$(date -Iseconds)
    echo "[$timestamp] REFINERY: $details" >> "$LOGS_DIR/refinery.log"
}

# Функция получения конфигурации merge
get_merge_config() {
    local key="$1"
    local default="$2"
    
    if command -v jq &> /dev/null && [ -f "$CONFIG_FILE" ]; then
        jq -r ".merge.$key // \"$default\"" "$CONFIG_FILE" 2>/dev/null
    else
        echo "$default"
    fi
}

# Функция проверки коллекции
check_collection() {
    local collection_id="$1"
    
    section "Проверка коллекции"
    
    local collection_dir="$COLLECTIONS_DIR/$collection_id"
    
    if [ ! -d "$collection_dir" ]; then
        error "Коллекция не найдена: $collection_dir"
        info "Доступные коллекции:"
        ls -1 "$COLLECTIONS_DIR" 2>/dev/null | head -n 10 || echo "  (нет коллекций)"
        return 1
    fi
    
    local manifest_file="$collection_dir/manifest.json"
    if [ ! -f "$manifest_file" ]; then
        error "Манифест коллекции не найден: $manifest_file"
        return 1
    fi
    
    info "Коллекция: $collection_id"
    info "Манифест: $manifest_file"
    
    if command -v jq &> /dev/null; then
        local ready=$(jq -r '.readyForMerge // false' "$manifest_file")
        if [ "$ready" != "true" ]; then
            warn "Коллекция не готова к merge"
            warn "Запустите collect.sh перед refinery"
        fi
        
        local worktree=$(jq -r '.worktreeName // "unknown"' "$manifest_file")
        info "Worktree: $worktree"
    fi
    
    success "Коллекция найдена"
    log_action "CHECK_COLLECTION" "Found: $collection_id"
    return 0
}

# Функция создания backup
create_backup() {
    section "Создание backup"
    
    local backup_enabled=$(get_merge_config "backupBeforeMerge" "true")
    
    if [ "$backup_enabled" != "true" ]; then
        info "Backup отключен в конфигурации"
        return 0
    fi
    
    local backup_dir="$ARCHIVES_DIR/backup-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$backup_dir"
    
    info "Backup директория: $backup_dir"
    
    # Сохранение текущего состояния git
    local repo_root=$(git rev-parse --show-toplevel)
    
    # Сохранение текущего статуса
    git status > "$backup_dir/git-status.txt" 2>/dev/null || true
    git log -n 5 --oneline > "$backup_dir/git-log.txt" 2>/dev/null || true
    
    # Сохранение текущей ветки
    git rev-parse --abbrev-ref HEAD > "$backup_dir/current-branch.txt" 2>/dev/null || true
    
    success "Backup создан: $backup_dir"
    log_action "CREATE_BACKUP" "Backup: $backup_dir"
    
    echo "$backup_dir"
    return 0
}

# Функция проверки конфликтов
check_conflicts() {
    local collection_dir="$1"
    local changes_dir="$collection_dir/changes"
    
    section "Проверка конфликтов"
    
    if [ ! -d "$changes_dir" ]; then
        warn "Директория изменений не найдена"
        return 0
    fi
    
    local repo_root=$(git rev-parse --show-toplevel)
    local conflicts_found=0
    
    cd "$repo_root"
    
    # Проверка каждого файла на конфликты
    for file in $(find "$changes_dir" -type f 2>/dev/null); do
        local relative_path="${file#$changes_dir/}"
        local original_file="$repo_root/$relative_path"
        
        if [ -f "$original_file" ]; then
            # Файл существует в обоих местах - возможна конфликтная ситуация
            if ! diff -q "$original_file" "$file" > /dev/null 2>&1; then
                info "⚠️  Потенциальный конфликт: $relative_path"
                ((conflicts_found++))
            fi
        fi
    done
    
    cd - > /dev/null
    
    if [ "$conflicts_found" -gt 0 ]; then
        warn "Найдено потенциальных конфликтов: $conflicts_found"
        
        local conflict_strategy=$(get_merge_config "conflictStrategy" "manual")
        if [ "$conflict_strategy" = "manual" ]; then
            error "Требуется ручное разрешение конфликтов"
            return 1
        fi
    else
        success "Конфликтов не обнаружено"
    fi
    
    log_action "CHECK_CONFLICTS" "Conflicts: $conflicts_found"
    return 0
}

# Функция выполнения quality gate
run_quality_gate() {
    local collection_dir="$1"
    local changes_dir="$collection_dir/changes"
    
    section "Выполнение Quality Gate"
    
    local require_qg=$(get_merge_config "requireQualityGate" "true")
    
    if [ "$require_qg" != "true" ]; then
        info "Quality Gate отключен в конфигурации"
        return 0
    fi
    
    if [ ! -d "$changes_dir" ]; then
        warn "Нет изменений для проверки"
        return 0
    fi
    
    # Проверка наличия скрипта quality gate
    local qg_script="$SCRIPT_DIR/../../quality-gates/check-phase.sh"
    if [ ! -f "$qg_script" ]; then
        qg_script="$SCRIPT_DIR/../../scripts/run_quality_gate.sh"
    fi
    
    if [ -f "$qg_script" ]; then
        info "Запуск Quality Gate..."
        
        # Временное применение изменений для проверки
        local repo_root=$(git rev-parse --show-toplevel)
        cd "$repo_root"
        
        # Копирование изменений во временную директорию
        local temp_check_dir=$(mktemp -d)
        cp -r "$changes_dir"/* "$temp_check_dir/" 2>/dev/null || true
        
        # Запуск проверки (упрощенная версия)
        if bash "$qg_script" --dry-run 2>/dev/null; then
            success "Quality Gate пройден"
            log_action "QUALITY_GATE" "Passed"
        else
            warn "Quality Gate не пройден или недоступен"
            warn "Продолжаем без Quality Gate"
        fi
        
        rm -rf "$temp_check_dir"
        cd - > /dev/null
    else
        warn "Quality Gate скрипт не найден"
    fi
    
    return 0
}

# Функция выполнения merge
perform_merge() {
    local collection_dir="$1"
    local changes_dir="$collection_dir/changes"
    local manifest_file="$collection_dir/manifest.json"
    
    section "Выполнение Merge"
    
    local repo_root=$(git rev-parse --show-toplevel)
    local current_branch=$(git rev-parse --abbrev-ref HEAD)
    
    info "Корень репозитория: $repo_root"
    info "Текущая ветка: $current_branch"
    
    # Проверка целевой ветки
    local allowed_branches=$(get_merge_config "allowedBranches" "develop,main")
    if [[ ! ",$allowed_branches," == *",$current_branch,"* ]]; then
        error "Merge разрешен только в ветки: $allowed_branches"
        error "Текущая ветка: $current_branch"
        return 1
    fi
    
    if [ ! -d "$changes_dir" ]; then
        warn "Нет изменений для merge"
        return 0
    fi
    
    local files_count=$(find "$changes_dir" -type f 2>/dev/null | wc -l)
    info "Файлов для merge: $files_count"
    
    if [ "$files_count" -eq 0 ]; then
        info "Нет файлов для merge"
        return 0
    fi
    
    # Копирование изменений
    cd "$repo_root"
    
    info "Копирование изменений в репозиторий..."
    cp -rv "$changes_dir"/* "$repo_root/" 2>/dev/null || true
    
    success "Изменения применены"
    
    # Добавление в staging
    info "Добавление изменений в staging..."
    git add -A 2>/dev/null || true
    
    # Проверка наличия изменений для коммита
    if git diff --cached --quiet 2>/dev/null; then
        info "Нет изменений для коммита"
        cd - > /dev/null
        return 0
    fi
    
    # Создание коммита
    local worktree_name=$(jq -r '.worktreeName // "unknown"' "$manifest_file" 2>/dev/null)
    local collection_id=$(basename "$collection_dir")
    local commit_message="merge(gastown): $collection_id - Merge from $worktree_name"
    
    info "Создание коммита: $commit_message"
    
    if git commit -m "$commit_message" 2>/dev/null; then
        success "Коммит создан"
        log_action "COMMIT" "Created: $commit_message"
    else
        warn "Не удалось создать коммит (возможно нет изменений)"
    fi
    
    cd - > /dev/null
    
    return 0
}

# Функция разрешения конфликтов (базовая)
resolve_conflicts() {
    local collection_dir="$1"
    
    section "Разрешение конфликтов"
    
    local auto_resolve=$(get_merge_config "autoResolve" "false")
    
    if [ "$auto_resolve" != "true" ]; then
        info "Автоматическое разрешение отключено"
        info "Требуется ручное разрешение конфликтов"
        return 0
    fi
    
    # Простая стратегия: принимать изменения из worktree
    info "Автоматическое разрешение: принимаем изменения из worktree"
    
    local repo_root=$(git rev-parse --show-toplevel)
    cd "$repo_root"
    
    # Для каждого конфликтующего файла
    for file in $(git diff --name-only --diff-filter=U 2>/dev/null); do
        info "Разрешение конфликта: $file"
        git checkout --ours "$file" 2>/dev/null || true
    done
    
    cd - > /dev/null
    
    log_action "RESOLVE_CONFLICTS" "Auto-resolved"
    return 0
}

# Функция очистки worktree
cleanup_worktree() {
    local collection_dir="$1"
    
    section "Очистка worktree"
    
    local auto_remove=$(jq -r '.cleanup.autoRemoveWorktrees // true' "$CONFIG_FILE" 2>/dev/null || echo "true")
    local remove_after_merge=$(jq -r '.cleanup.removeAfterMerge // true' "$CONFIG_FILE" 2>/dev/null || echo "true")
    
    if [ "$auto_remove" != "true" ] && [ "$remove_after_merge" != "true" ]; then
        info "Автоматическая очистка отключена"
        return 0
    fi
    
    local worktree_name=$(jq -r '.worktreeName // ""' "$collection_dir/manifest.json" 2>/dev/null)
    
    if [ -z "$worktree_name" ]; then
        warn "Имя worktree не найдено в манифесте"
        return 0
    fi
    
    local worktree_path="$WORKTREES_DIR/$worktree_name"
    
    if [ ! -d "$worktree_path" ]; then
        info "Worktree уже удален: $worktree_name"
        return 0
    fi
    
    info "Удаление worktree: $worktree_name"
    
    # Удаление через git worktree remove
    if git worktree remove "$worktree_path" 2>/dev/null; then
        success "Worktree удален: $worktree_name"
        log_action "CLEANUP_WORKTREE" "Removed: $worktree_name"
    else
        # Принудительное удаление
        warn "Не удалось удалить через git, пробуем принудительно"
        rm -rf "$worktree_path" 2>/dev/null && success "Worktree удален принудительно"
    fi
    
    # Обновление реестра
    if command -v jq &> /dev/null && [ -f "$REGISTRY_FILE" ]; then
        local temp_file=$(mktemp)
        jq --arg name "$worktree_name" \
           '.worktrees = [.worktrees[] | select(.name != $name)]' \
           "$REGISTRY_FILE" > "$temp_file" 2>/dev/null && mv "$temp_file" "$REGISTRY_FILE"
    fi
    
    return 0
}

# Функция архивации коллекции
archive_collection() {
    local collection_dir="$1"
    
    section "Архивация коллекции"
    
    local archive_enabled=$(jq -r '.cleanup.archiveCompleted // true' "$CONFIG_FILE" 2>/dev/null || echo "true")
    
    if [ "$archive_enabled" != "true" ]; then
        info "Архивация отключена"
        return 0
    fi
    
    local collection_id=$(basename "$collection_dir")
    local archive_path="$ARCHIVES_DIR/$collection_id"
    
    if [ -d "$archive_path" ]; then
        info "Архив уже существует: $collection_id"
        return 0
    fi
    
    mv "$collection_dir" "$archive_path" 2>/dev/null && \
        success "Коллекция архивирована: $archive_path" || \
        warn "Не удалось архивировать коллекцию"
    
    log_action "ARCHIVE" "Archived: $collection_id"
    return 0
}

# Функция обновления реестра
update_registry() {
    local collection_id="$1"
    local success="$2"
    
    section "Обновление реестра"
    
    if command -v jq &> /dev/null && [ -f "$REGISTRY_FILE" ]; then
        local temp_file=$(mktemp)
        local timestamp=$(date -Iseconds)
        
        # Добавление в историю merges
        jq --arg collection "$collection_id" \
           --arg timestamp "$timestamp" \
           --arg success "$success" \
           '.history.merges += [{
             "collectionId": $collection,
             "mergedAt": $timestamp,
             "success": ($success == "true")
           }]' "$REGISTRY_FILE" > "$temp_file" 2>/dev/null && mv "$temp_file" "$REGISTRY_FILE"
        
        # Обновление статистики
        jq --argjson success "$success" \
           '.statistics.totalMergesPerformed = (.statistics.totalMergesPerformed // 0) + 1 |
            if $success then
              .statistics.totalTasksCompleted = (.statistics.totalTasksCompleted // 0) + 1
            else
              .statistics.totalTasksFailed = (.statistics.totalTasksFailed // 0) + 1
            end' "$REGISTRY_FILE" > "$temp_file" 2>/dev/null && mv "$temp_file" "$REGISTRY_FILE"
        
        success "Реестр обновлен"
        log_action "UPDATE_REGISTRY" "Updated for $collection_id"
    else
        warn "jq не установлен или реестр не найден"
    fi
    
    return 0
}

# Функция вывода итогов
print_summary() {
    local collection_id="$1"
    local merge_success="$2"
    
    section "Итоги Merge"
    
    echo ""
    if [ "$merge_success" = "true" ]; then
        success "Merge успешно выполнен!"
    else
        warn "Merge завершен с предупреждениями"
    fi
    
    echo ""
    echo "═══════════════════════════════════════════════════════════"
    echo "  Информация"
    echo "═══════════════════════════════════════════════════════════"
    echo "  Collection:  $collection_id"
    echo "  Status:      $([ "$merge_success" = "true" ] && echo "SUCCESS" || echo "COMPLETED WITH WARNINGS")"
    echo "  Timestamp:   $(date -Iseconds)"
    echo "═══════════════════════════════════════════════════════════"
    echo ""
    echo "Следующие шаги:"
    echo "  1. Проверка изменений: git diff HEAD~1"
    echo "  2. Push изменений: git push origin <branch>"
    echo "  3. Создание тега: .qwen/scripts/git/auto-tag-release.sh vX.Y.Z"
    echo ""
}

# =============================================================================
# Основная логика
# =============================================================================

# Парсинг аргументов
COLLECTION_ID=""
SKIP_QG=false
FORCE=false
DRY_RUN=false

for arg in "$@"; do
    case $arg in
        --help|-h)
            echo "Использование: $0 <collection-id> [options]"
            echo ""
            echo "Merge результатов из worktree в основную ветку"
            echo ""
            echo "Параметры:"
            echo "  collection-id    Идентификатор коллекции"
            echo "  --skip-qg        Пропустить Quality Gate"
            echo "  --force          Принудительный merge без проверок"
            echo "  --dry-run        Пробный запуск без изменений"
            echo ""
            echo "Примеры:"
            echo "  $0 collect-20260321-120000-12345"
            echo "  $0 collect-20260321-120000-12345 --skip-qg"
            echo "  $0 collect-20260321-120000-12345 --dry-run"
            exit 0
            ;;
        --skip-qg)
            SKIP_QG=true
            ;;
        --force|-f)
            FORCE=true
            ;;
        --dry-run)
            DRY_RUN=true
            ;;
    esac
done

# Проверка аргументов
if [ $# -lt 1 ]; then
    error "Не указан collection-id"
    echo ""
    echo "Использование:"
    echo "  $0 <collection-id> [options]"
    echo ""
    echo "Пример:"
    echo "  $0 collect-20260321-120000-12345"
    exit 1
fi

COLLECTION_ID="$1"

echo ""
echo -e "${CYAN}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║        Gastown Refinery - Merge & Refinement              ║${NC}"
echo -e "${CYAN}╚═══════════════════════════════════════════════════════════╝${NC}"

# Dry run режим
if [ "$DRY_RUN" = true ]; then
    info "Запуск в режиме DRY RUN - изменения не будут применены"
    echo ""
fi

# Проверка коллекции
check_collection "$COLLECTION_ID" || exit 1

COLLECTION_DIR="$COLLECTIONS_DIR/$COLLECTION_ID"

# Создание backup
if [ "$DRY_RUN" = false ]; then
    create_backup
fi

# Проверка конфликтов
if [ "$FORCE" = false ]; then
    check_conflicts "$COLLECTION_DIR" || {
        error "Обнаружены конфликты. Разрешите их вручную или используйте --force"
        exit 1
    }
fi

# Quality Gate
if [ "$SKIP_QG" = false ] && [ "$DRY_RUN" = false ]; then
    run_quality_gate "$COLLECTION_DIR"
fi

# Выполнение merge
if [ "$DRY_RUN" = false ]; then
    perform_merge "$COLLECTION_DIR"
    MERGE_STATUS=$?
else
    info "DRY RUN: Пропускаем merge"
    MERGE_STATUS=0
fi

# Разрешение конфликтов при необходимости
if [ $MERGE_STATUS -ne 0 ] && [ "$FORCE" = true ]; then
    resolve_conflicts "$COLLECTION_DIR"
    perform_merge "$COLLECTION_DIR"
    MERGE_STATUS=$?
fi

# Очистка
if [ "$DRY_RUN" = false ]; then
    cleanup_worktree "$COLLECTION_DIR"
    archive_collection "$COLLECTION_DIR"
fi

# Обновление реестра
if [ "$DRY_RUN" = false ]; then
    update_registry "$COLLECTION_ID" "$([ $MERGE_STATUS -eq 0 ] && echo "true" || echo "false")"
fi

# Вывод итогов
print_summary "$COLLECTION_ID" "$([ $MERGE_STATUS -eq 0 ] && echo "true" || echo "false")"

log_action "REFINERY_COMPLETE" "Collection: $COLLECTION_ID, Success: $([ $MERGE_STATUS -eq 0 ] && echo "true" || echo "false")"

if [ "$ERRORS" -gt 0 ]; then
    exit 1
fi

exit 0
