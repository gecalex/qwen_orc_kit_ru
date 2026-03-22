#!/bin/bash
# =============================================================================
# onboard.sh - Gastown Worktree Initialization
# =============================================================================
# Назначение: Инициализация Gastown и создание worktree для агента
#
# Использование:
#   .qwen/scripts/gastown/onboard.sh <agent-id> [task-id] [branch]
#
# Пример:
#   .qwen/scripts/gastown/onboard.sh "dev-specialist" "task-001" "develop"
#
# Выход:
#   Успех: путь к worktree (stdout)
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

# =============================================================================
# Функции
# =============================================================================

error() {
    echo -e "${RED}❌ ОШИБКА:${NC} $1" >&2
    ((ERRORS++))
}

warn() {
    echo -e "${YELLOW}⚠️  ПРЕДУПРЕЖДЕНИЕ:${NC} $1" >&2
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
    echo "[$timestamp] $action: $details" >> "$LOGS_DIR/onboard.log"
}

# Функция проверки git worktree поддержки
check_git_worktree_support() {
    section "Проверка поддержки git worktree"
    
    if ! command -v git &> /dev/null; then
        error "Git не установлен"
        return 1
    fi
    
    local git_version=$(git --version | cut -d' ' -f3)
    info "Версия Git: $git_version"
    
    # Проверка команды worktree
    if ! git worktree --help &> /dev/null; then
        error "Git worktree не поддерживается в этой версии Git"
        return 1
    fi
    
    success "Git worktree поддерживается"
    log_action "CHECK_WORKTREE" "Git worktree supported"
    return 0
}

# Функция проверки репозитория
check_repository() {
    section "Проверка репозитория"
    
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        error "Текущая директория не является git репозиторием"
        return 1
    fi
    
    local root_dir=$(git rev-parse --show-toplevel)
    info "Корень репозитория: $root_dir"
    
    success "Git репозиторий найден"
    log_action "CHECK_REPO" "Repository: $root_dir"
    return 0
}

# Функция проверки конфигурации
check_config() {
    section "Проверка конфигурации"
    
    if [ ! -f "$CONFIG_FILE" ]; then
        error "Файл конфигурации не найден: $CONFIG_FILE"
        return 1
    fi
    
    info "Конфигурация: $CONFIG_FILE"
    
    # Проверка JSON валидности
    if command -v jq &> /dev/null; then
        if ! jq empty "$CONFIG_FILE" 2>/dev/null; then
            error "Невалидный JSON в конфигурации"
            return 1
        fi
        success "Конфигурация валидна"
    else
        warn "jq не установлен, пропускаем проверку JSON"
    fi
    
    log_action "CHECK_CONFIG" "Config file: $CONFIG_FILE"
    return 0
}

# Функция инициализации директорий
init_directories() {
    section "Инициализация директорий"
    
    # Создание директорий
    mkdir -p "$WORKTREES_DIR"
    mkdir -p "$LOGS_DIR"
    mkdir -p "$GASTOWN_DIR/metrics"
    mkdir -p "$GASTOWN_DIR/archives"
    
    info "Созданы директории:"
    echo "  - $WORKTREES_DIR"
    echo "  - $LOGS_DIR"
    echo "  - $GASTOWN_DIR/metrics"
    echo "  - $GASTOWN_DIR/archives"
    
    success "Директории инициализированы"
    log_action "INIT_DIRS" "Directories created"
    return 0
}

# Функция проверки существующих worktree
check_existing_worktrees() {
    section "Проверка существующих worktree"
    
    local worktree_count=$(git worktree list 2>/dev/null | wc -l)
    info "Существующих worktree: $worktree_count"
    
    # Вывод списка worktree
    git worktree list 2>/dev/null | while read -r line; do
        info "  $line"
    done
    
    # Проверка на максимальное количество
    local max_worktrees=$(jq -r '.worktree.maxWorktrees // 10' "$CONFIG_FILE" 2>/dev/null || echo "10")
    if [ "$worktree_count" -ge "$max_worktrees" ]; then
        warn "Достигнуто максимальное количество worktree ($max_worktrees)"
        warn "Рассмотрите очистку старых worktree"
    fi
    
    log_action "CHECK_WORKTREES" "Count: $worktree_count"
    return 0
}

# Функция создания worktree
create_worktree() {
    local agent_id="$1"
    local task_id="$2"
    local branch="$3"
    
    section "Создание worktree"
    
    # Формирование имени worktree
    local worktree_name="agent-${agent_id}"
    if [ -n "$task_id" ]; then
        worktree_name="${worktree_name}-${task_id}"
    fi
    
    # Санитизация имени
    worktree_name=$(echo "$worktree_name" | tr '[:upper:]' '[:lower:]' | tr -cd 'a-z0-9-_')
    
    local worktree_path="$WORKTREES_DIR/$worktree_name"
    
    info "Имя worktree: $worktree_name"
    info "Путь worktree: $worktree_path"
    info "Базовая ветка: $branch"
    
    # Проверка существования worktree
    if [ -d "$worktree_path" ]; then
        error "Worktree уже существует: $worktree_path"
        warn "Удалите существующий worktree или используйте другое имя"
        return 1
    fi
    
    # Проверка существования ветки
    if ! git show-ref --verify --quiet refs/heads/"$branch" && \
       ! git show-ref --verify --quiet refs/remotes/origin/"$branch"; then
        error "Ветка '$branch' не найдена"
        return 1
    fi
    
    # Создание worktree
    info "Создание worktree..."
    if git worktree add -b "$worktree_name" "$worktree_path" "$branch" 2>/dev/null; then
        success "Worktree создан: $worktree_path"
        log_action "CREATE_WORKTREE" "Created: $worktree_path from $branch"
    else
        # Попытка без создания новой ветки
        if git worktree add "$worktree_path" "$branch" 2>/dev/null; then
            success "Worktree создан: $worktree_path"
            log_action "CREATE_WORKTREE" "Created: $worktree_path from $branch"
        else
            error "Не удалось создать worktree"
            return 1
        fi
    fi
    
    # Вывод пути к worktree
    echo "$worktree_path"
    return 0
}

# Функция настройки окружения worktree
setup_worktree_env() {
    local worktree_path="$1"
    local agent_id="$2"
    
    section "Настройка окружения worktree"
    
    info "Путь: $worktree_path"
    info "Агент: $agent_id"
    
    # Создание локальной конфигурации
    local env_file="$worktree_path/.qwen/gastown.env"
    mkdir -p "$(dirname "$env_file")"
    
    cat > "$env_file" << EOF
# Gastown Environment Configuration
# Generated: $(date -Iseconds)

GASTOWN_AGENT_ID="$agent_id"
GASTOWN_WORKTREE_NAME="$(basename "$worktree_path")"
GASTOWN_WORKTREE_PATH="$worktree_path"
GASTOWN_PARENT_REPO="$(git rev-parse --show-toplevel)"
GASTOWN_INITIALIZED="$(date -Iseconds)"
GASTOWN_STATUS="active"

# Изоляция окружения
GASTOWN_ISOLATED="true"
GASTOWN_SHARED_OBJECTS="false"
EOF
    
    success "Окружение настроено: $env_file"
    
    # Создание файла состояния
    local state_file="$worktree_path/.qwen/gastown-state.json"
    cat > "$state_file" << EOF
{
  "agentId": "$agent_id",
  "worktreeName": "$(basename "$worktree_path")",
  "worktreePath": "$worktree_path",
  "initializedAt": "$(date -Iseconds)",
  "status": "active",
  "taskId": null,
  "lastHeartbeat": "$(date -Iseconds)",
  "metrics": {
    "startTime": $(date +%s),
    "cpuUsage": 0,
    "memoryUsage": 0
  }
}
EOF
    
    success "Файл состояния создан: $state_file"
    log_action "SETUP_ENV" "Environment configured for $agent_id"
    return 0
}

# Функция регистрации в реестре
register_in_registry() {
    local agent_id="$1"
    local task_id="$2"
    local worktree_path="$3"
    local branch="$4"
    
    section "Регистрация в реестре"
    
    local worktree_name=$(basename "$worktree_path")
    local timestamp=$(date -Iseconds)
    
    if command -v jq &> /dev/null && [ -f "$REGISTRY_FILE" ]; then
        # Чтение текущего реестра
        local temp_file=$(mktemp)
        
        # Добавление записи о worktree
        jq --arg name "$worktree_name" \
           --arg path "$worktree_path" \
           --arg agent "$agent_id" \
           --arg task "${task_id:-null}" \
           --arg branch "$branch" \
           --arg status "active" \
           --arg created "$timestamp" \
           '.worktrees += [{
             "name": $name,
             "path": $path,
             "agentId": $agent,
             "taskId": (if $task == "null" then null else $task end),
             "branch": $branch,
             "status": $status,
             "createdAt": $created,
             "lastHeartbeat": $created
           }]' "$REGISTRY_FILE" > "$temp_file" && mv "$temp_file" "$REGISTRY_FILE"
        
        success "Worktree зарегистрирован в реестре"
        log_action "REGISTER" "Registered $worktree_name in registry"
    else
        warn "jq не установлен или реестр не найден, пропускаем регистрацию"
    fi
    
    return 0
}

# Функция вывода итогов
print_summary() {
    local agent_id="$1"
    local task_id="$2"
    local worktree_path="$3"
    
    section "Итоги инициализации"
    
    echo ""
    success "Gastown worktree успешно инициализирован!"
    echo ""
    echo "═══════════════════════════════════════════════════════════"
    echo "  Информация"
    echo "═══════════════════════════════════════════════════════════"
    echo "  Агент:       $agent_id"
    echo "  Задача:      ${task_id:-не назначена}"
    echo "  Worktree:    $(basename "$worktree_path")"
    echo "  Путь:        $worktree_path"
    echo "═══════════════════════════════════════════════════════════"
    echo ""
    echo "Следующие шаги:"
    echo "  1. Перейдите в worktree: cd $worktree_path"
    echo "  2. Отправьте задачу: .qwen/scripts/gastown/dispatch.sh <task>"
    echo "  3. Мониторинг: .qwen/scripts/gastown/monitor.sh"
    echo ""
}

# =============================================================================
# Основная логика
# =============================================================================

# Парсинг аргументов
AGENT_ID=""
TASK_ID=""
BRANCH="develop"

for arg in "$@"; do
    case $arg in
        --help|-h)
            echo "Использование: $0 <agent-id> [task-id] [branch]"
            echo ""
            echo "Инициализация Gastown и создание worktree для агента"
            echo ""
            echo "Параметры:"
            echo "  agent-id    Идентификатор агента"
            echo "  task-id     Идентификатор задачи (опционально)"
            echo "  branch      Базовая ветка (по умолчанию: develop)"
            echo ""
            echo "Примеры:"
            echo "  $0 dev-specialist task-001 develop"
            echo "  $0 bug-hunter bugfix-002"
            exit 0
            ;;
    esac
done

# Проверка аргументов
if [ $# -lt 1 ]; then
    error "Не указан agent-id"
    echo ""
    echo "Использование:"
    echo "  $0 <agent-id> [task-id] [branch]"
    echo ""
    echo "Пример:"
    echo "  $0 dev-specialist task-001 develop"
    exit 1
fi

AGENT_ID="$1"
TASK_ID="${2:-}"
BRANCH="${3:-develop}"

# Проверка валидности agent-id
if [[ ! "$AGENT_ID" =~ ^[a-z0-9_-]+$ ]]; then
    error "Невалидный agent-id. Используйте только строчные буквы, цифры, дефисы и подчеркивания"
    exit 1
fi

echo ""
echo -e "${CYAN}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║        Gastown Onboard - Worktree Initialization          ║${NC}"
echo -e "${CYAN}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""

# Запуск проверок
check_git_worktree_support || { print_summary "$AGENT_ID" "$TASK_ID" ""; exit 1; }
check_repository || { print_summary "$AGENT_ID" "$TASK_ID" ""; exit 1; }
check_config || { print_summary "$AGENT_ID" "$TASK_ID" ""; exit 1; }
init_directories
check_existing_worktrees

# Создание worktree
WORKTREE_PATH=$(create_worktree "$AGENT_ID" "$TASK_ID" "$BRANCH")
if [ $? -ne 0 ] || [ -z "$WORKTREE_PATH" ]; then
    error "Не удалось создать worktree"
    exit 1
fi

# Настройка окружения
setup_worktree_env "$WORKTREE_PATH" "$AGENT_ID"

# Регистрация в реестре
register_in_registry "$AGENT_ID" "$TASK_ID" "$WORKTREE_PATH" "$BRANCH"

# Вывод итогов
print_summary "$AGENT_ID" "$TASK_ID" "$WORKTREE_PATH"

if [ "$ERRORS" -gt 0 ]; then
    exit 1
fi

exit 0
