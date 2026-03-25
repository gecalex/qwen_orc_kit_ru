#!/bin/bash
# =============================================================================
# collect.sh - Gastown Results Collection
# =============================================================================
# Назначение: Сбор результатов из worktree и подготовка к merge
#
# Использование:
#   .qwen/scripts/gastown/collect.sh <worktree-name> [task-id]
#
# Пример:
#   .qwen/scripts/gastown/collect.sh "agent-dev-specialist-task-001"
#
# Выход:
#   Успех: путь к собранным результатам (stdout)
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
    echo "[$timestamp] COLLECT: $details" >> "$LOGS_DIR/collect.log"
}

# Функция проверки worktree
check_worktree() {
    local worktree_name="$1"
    
    section "Проверка worktree"
    
    local worktree_path="$WORKTREES_DIR/$worktree_name"
    
    if [ ! -d "$worktree_path" ]; then
        error "Worktree не найден: $worktree_path"
        return 1
    fi
    
    info "Worktree: $worktree_path"
    success "Worktree найден"
    log_action "CHECK_WORKTREE" "Found: $worktree_name"
    return 0
}

# Функция поиска задач в worktree
find_tasks() {
    local worktree_name="$1"
    local task_id="$2"
    local worktree_path="$WORKTREES_DIR/$worktree_name"
    
    section "Поиск задач"
    
    local tasks_dir="$worktree_path/.qwen/gastown/tasks"
    
    if [ ! -d "$tasks_dir" ]; then
        warn "Директория задач не найдена: $tasks_dir"
        return 0
    fi
    
    if [ -n "$task_id" ]; then
        # Поиск конкретной задачи
        local task_path="$tasks_dir/$task_id"
        if [ -d "$task_path" ]; then
            info "Задача найдена: $task_id"
            echo "$task_path"
        else
            error "Задача не найдена: $task_id"
            return 1
        fi
    else
        # Поиск последней активной задачи
        local latest_task=$(ls -td "$tasks_dir"/*/ 2>/dev/null | head -n1 | sed 's/\/$//')
        if [ -n "$latest_task" ]; then
            task_id=$(basename "$latest_task")
            info "Последняя задача: $task_id"
            echo "$latest_task"
        else
            warn "Задачи не найдены в worktree"
        fi
    fi
    
    return 0
}

# Функция проверки статуса задачи
check_task_status() {
    local task_path="$1"
    
    section "Проверка статуса задачи"
    
    local task_file="$task_path/task.json"
    
    if [ ! -f "$task_file" ]; then
        error "Файл задачи не найден: $task_file"
        return 1
    fi
    
    if command -v jq &> /dev/null; then
        local status=$(jq -r '.status // "unknown"' "$task_file" 2>/dev/null)
        local completed_at=$(jq -r '.completedAt // "null"' "$task_file" 2>/dev/null)
        
        info "Статус задачи: $status"
        info "Завершена: ${completed_at:-нет}"
        
        if [ "$status" = "dispatched" ] || [ "$status" = "running" ]; then
            warn "Задача еще не завершена"
            warn "Дождитесь завершения задачи перед сбором результатов"
            return 1
        fi
        
        if [ "$status" = "failed" ] || [ "$status" = "error" ]; then
            local error_msg=$(jq -r '.error // "Неизвестная ошибка"' "$task_file" 2>/dev/null)
            warn "Задача завершилась с ошибкой: $error_msg"
        fi
        
        if [ "$status" = "completed" ] || [ "$status" = "success" ]; then
            success "Задача успешно завершена"
        fi
    else
        warn "jq не установлен, пропускаем проверку статуса"
    fi
    
    log_action "CHECK_TASK_STATUS" "Status checked"
    return 0
}

# Функция валидации изменений
validate_changes() {
    local worktree_path="$1"
    local task_path="$2"
    
    section "Валидация изменений"
    
    info "Worktree: $worktree_path"
    
    # Переход в worktree для git операций
    cd "$worktree_path"
    
    # Проверка git статуса
    local changed_files=$(git status --porcelain 2>/dev/null | wc -l)
    info "Измененных файлов: $changed_files"
    
    if [ "$changed_files" -gt 0 ]; then
        info "Список изменений:"
        git status --porcelain 2>/dev/null | head -n 20
        if [ "$changed_files" -gt 20 ]; then
            echo "  ... и еще $((changed_files - 20)) файлов"
        fi
    else
        info "Нет изменений в working directory"
    fi
    
    # Проверка staged изменений
    local staged_files=$(git diff --cached --name-only 2>/dev/null | wc -l)
    info "Staged файлов: $staged_files"
    
    # Проверка наличия отчета
    local report_found=false
    if [ -f "$task_path/report.md" ]; then
        report_found=true
        info "✅ Отчет найден: $task_path/report.md"
    fi
    
    if [ -f "$task_path/Report.md" ]; then
        report_found=true
        info "✅ Отчет найден: $task_path/Report.md"
    fi
    
    # Поиск отчетов в поддиректориях
    local reports=$(find "$task_path" -name "*.md" -o -name "*.json" 2>/dev/null | head -n 10)
    if [ -n "$reports" ]; then
        info "Артефакты задачи:"
        echo "$reports" | while read -r file; do
            echo "  - $(basename "$file")"
        done
    fi
    
    if [ "$report_found" = false ]; then
        warn "Отчет не найден в задаче"
    else
        success "Отчет найден"
    fi
    
    # Возврат в исходную директорию
    cd - > /dev/null
    
    log_action "VALIDATE_CHANGES" "Validated: $changed_files files changed"
    return 0
}

# Функция сбора результатов
collect_results() {
    local worktree_name="$1"
    local task_path="$2"
    local worktree_path="$WORKTREES_DIR/$worktree_name"
    
    section "Сбор результатов"
    
    # Создание директории для сбора
    local collection_id="collect-$(date +%Y%m%d-%H%M%S)-$$"
    local collection_dir="$COLLECTIONS_DIR/$collection_id"
    mkdir -p "$collection_dir"
    
    info "Collection ID: $collection_id"
    info "Collection Dir: $collection_dir"
    
    # Копирование результатов задачи
    local results_dir="$collection_dir/results"
    mkdir -p "$results_dir"
    
    info "Копирование результатов задачи..."
    if [ -d "$task_path" ]; then
        cp -r "$task_path"/* "$results_dir/" 2>/dev/null || true
        success "Результаты скопированы"
    fi
    
    # Сбор измененных файлов из worktree
    local changes_dir="$collection_dir/changes"
    mkdir -p "$changes_dir"
    
    cd "$worktree_path"
    
    info "Сбор измененных файлов..."
    local changed_count=0
    
    # Сбор staged изменений
    for file in $(git diff --cached --name-only 2>/dev/null); do
        local file_dir=$(dirname "$changes_dir/$file")
        mkdir -p "$file_dir"
        cp "$worktree_path/$file" "$changes_dir/$file" 2>/dev/null || true
        ((changed_count++))
    done
    
    # Сбор unstaged изменений
    for file in $(git diff --name-only 2>/dev/null); do
        if [ ! -f "$changes_dir/$file" ]; then
            local file_dir=$(dirname "$changes_dir/$file")
            mkdir -p "$file_dir"
            cp "$worktree_path/$file" "$changes_dir/$file" 2>/dev/null || true
            ((changed_count++))
        fi
    done
    
    cd - > /dev/null
    
    info "Собрано файлов: $changed_count"
    
    # Создание манифеста коллекции
    local manifest_file="$collection_dir/manifest.json"
    local timestamp=$(date -Iseconds)
    
    cat > "$manifest_file" << EOF
{
  "collectionId": "$collection_id",
  "worktreeName": "$worktree_name",
  "worktreePath": "$worktree_path",
  "taskPath": "$task_path",
  "collectedAt": "$timestamp",
  "status": "collected",
  "results": {
    "reportFound": $([ -f "$task_path/report.md" ] && echo "true" || echo "false"),
    "filesChanged": $changed_count,
    "artifactsCount": $(find "$results_dir" -type f 2>/dev/null | wc -l)
  },
  "readyForMerge": true,
  "mergeTarget": null,
  "conflicts": []
}
EOF
    
    success "Манифест создан: $manifest_file"
    log_action "COLLECT_RESULTS" "Collection: $collection_id, files: $changed_count"
    
    echo "$collection_dir"
    return 0
}

# Функция подготовки к merge
prepare_for_merge() {
    local collection_dir="$1"
    
    section "Подготовка к merge"
    
    local manifest_file="$collection_dir/manifest.json"
    
    if command -v jq &> /dev/null && [ -f "$manifest_file" ]; then
        local temp_file=$(mktemp)
        
        # Обновление статуса
        jq '.readyForMerge = true | .preparedAt = "'"$(date -Iseconds)"'"' \
           "$manifest_file" > "$temp_file" && mv "$temp_file" "$manifest_file"
        
        success "Коллекция готова к merge"
    fi
    
    # Создание файла для refinery
    local merge_prep_file="$collection_dir/merge-prep.json"
    cat > "$merge_prep_file" << EOF
{
  "collectionId": "$(basename "$collection_dir")",
  "status": "ready",
  "validatedAt": "$(date -Iseconds)",
  "requiresReview": true,
  "autoMerge": false
}
EOF
    
    info "Файл подготовки создан: $merge_prep_file"
    log_action "PREPARE_MERGE" "Prepared: $collection_dir"
    return 0
}

# Функция обновления реестра
update_registry() {
    local worktree_name="$1"
    local collection_id="$2"
    
    section "Обновление реестра"
    
    if command -v jq &> /dev/null && [ -f "$REGISTRY_FILE" ]; then
        local temp_file=$(mktemp)
        local timestamp=$(date -Iseconds)
        
        # Обновление записи о worktree
        jq --arg name "$worktree_name" \
           --arg status "collected" \
           --arg heartbeat "$timestamp" \
           '(.worktrees[] | select(.name == $name)) |= (.status = $status | .lastHeartbeat = $heartbeat)' \
           "$REGISTRY_FILE" > "$temp_file" 2>/dev/null && mv "$temp_file" "$REGISTRY_FILE"
        
        # Перемещение задачи из active в completed
        jq --arg collection "$collection_id" \
           '.tasks.completed += [{
             "collectionId": $collection,
             "collectedAt": "'"$(date -Iseconds)"'"
           }] | .tasks.active = [.tasks.active[] | select(.worktree != "'$worktree_name'")]' \
           "$REGISTRY_FILE" > "$temp_file" 2>/dev/null && mv "$temp_file" "$REGISTRY_FILE"
        
        success "Реестр обновлен"
        log_action "UPDATE_REGISTRY" "Updated for $worktree_name"
    else
        warn "jq не установлен или реестр не найден"
    fi
    
    return 0
}

# Функция вывода итогов
print_summary() {
    local worktree_name="$1"
    local collection_dir="$2"
    
    section "Итоги сбора результатов"
    
    echo ""
    success "Результаты успешно собраны!"
    echo ""
    echo "═══════════════════════════════════════════════════════════"
    echo "  Информация о коллекции"
    echo "═══════════════════════════════════════════════════════════"
    echo "  Collection:  $(basename "$collection_dir")"
    echo "  Worktree:    $worktree_name"
    echo "  Путь:        $collection_dir"
    echo "  Статус:      ready for merge"
    echo "═══════════════════════════════════════════════════════════"
    echo ""
    echo "Следующие шаги:"
    echo "  1. Ревью изменений: cd $collection_dir && cat manifest.json"
    echo "  2. Merge результатов: .qwen/scripts/gastown/refinery.sh $(basename "$collection_dir")"
    echo "  3. Очистка: .qwen/scripts/gastown/cleanup.sh $worktree_name"
    echo ""
}

# =============================================================================
# Основная логика
# =============================================================================

# Парсинг аргументов
WORKTREE_NAME=""
TASK_ID=""

for arg in "$@"; do
    case $arg in
        --help|-h)
            echo "Использование: $0 <worktree-name> [task-id]"
            echo ""
            echo "Сбор результатов из worktree и подготовка к merge"
            echo ""
            echo "Параметры:"
            echo "  worktree-name  Имя worktree агента"
            echo "  task-id        Идентификатор задачи (опционально)"
            echo ""
            echo "Примеры:"
            echo "  $0 agent-dev-specialist-task-001"
            echo "  $0 agent-bug-hunter-002 task-20260321-120000"
            exit 0
            ;;
    esac
done

# Проверка аргументов
if [ $# -lt 1 ]; then
    error "Не указан worktree-name"
    echo ""
    echo "Использование:"
    echo "  $0 <worktree-name> [task-id]"
    echo ""
    echo "Пример:"
    echo "  $0 agent-dev-specialist-task-001"
    exit 1
fi

WORKTREE_NAME="$1"
TASK_ID="${2:-}"

echo ""
echo -e "${CYAN}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║         Gastown Collect - Results Collection              ║${NC}"
echo -e "${CYAN}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""

# Запуск проверок
check_worktree "$WORKTREE_NAME" || exit 1

# Поиск задач
TASK_PATH=$(find_tasks "$WORKTREE_NAME" "$TASK_ID")
if [ -z "$TASK_PATH" ]; then
    error "Задачи не найдены"
    exit 1
fi

# Проверка статуса
check_task_status "$TASK_PATH" || warn "Продолжаем сбор несмотря на статус"

# Валидация изменений
validate_changes "$WORKTREES_DIR/$WORKTREE_NAME" "$TASK_PATH"

# Сбор результатов
COLLECTION_DIR=$(collect_results "$WORKTREE_NAME" "$TASK_PATH")
if [ $? -ne 0 ] || [ -z "$COLLECTION_DIR" ]; then
    error "Не удалось собрать результаты"
    exit 1
fi

# Подготовка к merge
prepare_for_merge "$COLLECTION_DIR"

# Обновление реестра
update_registry "$WORKTREE_NAME" "$(basename "$COLLECTION_DIR")"

# Вывод итогов
print_summary "$WORKTREE_NAME" "$COLLECTION_DIR"

# Вывод пути для использования в скриптах
echo "$COLLECTION_DIR"

if [ "$ERRORS" -gt 0 ]; then
    exit 1
fi

exit 0
