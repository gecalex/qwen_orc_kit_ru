#!/bin/bash
#
# assign-agents-to-tasks.sh
# Назначение: Автоматическое назначение специализированных агентов на задачи из tasks.md
# Версия: 1.0.0
# Использование: .qwen/scripts/specification-tools/assign-agents-to-tasks.sh [SPEC_ID]
#

set -e

# Конфигурация
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
SPECS_DIR="$PROJECT_ROOT/specs"
AGENTS_DIR="$PROJECT_ROOT/.qwen/agents"
TMP_DIR="$PROJECT_ROOT/.tmp/current"

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Логирование
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_header() { echo -e "${CYAN}========================================${NC}"; }

# Получение SPEC_ID
SPEC_ID="${1:-current}"
TASKS_FILE="$SPECS_DIR/$SPEC_ID/tasks.md"

log_header
echo "  Назначение агентов на задачи"
log_header
echo ""
log_info "Spec ID: $SPEC_ID"
log_info "Файл задач: $TASKS_FILE"
echo ""

# Проверка наличия tasks.md
if [ ! -f "$TASKS_FILE" ]; then
    log_error "tasks.md не найден в $TASKS_FILE"
    log_info "Запустите сначала: speckit.tasks"
    exit 1
fi

log_success "tasks.md найден"

# Создание временной директории
mkdir -p "$TMP_DIR"

# ============================================
# ФУНКЦИЯ: Проверка существования агента
# ============================================
check_agent_exists() {
    local agent_name="$1"
    local agent_file="$AGENTS_DIR/${agent_name}.md"
    
    if [ -f "$agent_file" ]; then
        return 0
    else
        return 1
    fi
}

# ============================================
# ФУНКЦИЯ: Определение типа агента по задаче
# ============================================
determine_agent_type() {
    local task_description="$1"
    local task_name="$2"
    
    # Приведение к нижнему регистру для анализа
    local text_lower=$(echo "$task_description $task_name" | tr '[:upper:]' '[:lower:]')
    
    # Backend задачи
    if echo "$text_lower" | grep -qE "(api|backend|database|db|sql|postgres|mysql|mongodb|redis|server|endpoint|route|controller|model|migration|alembic|sqlalchemy|fastapi|django|flask)"; then
        echo "work_backend"
        return 0
    fi
    
    # Frontend задачи
    if echo "$text_lower" | grep -qE "(frontend|ui|component|react|vue|angular|html|css|bootstrap|material|style|layout|view|template|jsx|tsx|webpack|vite)"; then
        echo "work_frontend"
        return 0
    fi
    
    # Testing задачи
    if echo "$text_lower" | grep -qE "(test|spec|pytest|jest|coverage|mock|fixture|assert|e2e|integration|unit|validation|check)"; then
        echo "work_testing"
        return 0
    fi
    
    # Documentation задачи
    if echo "$text_lower" | grep -qE "(doc|readme|comment|documentation|manual|guide|tutorial|translation|translate)"; then
        echo "tech-translator-ru"
        return 0
    fi
    
    # Security задачи
    if echo "$text_lower" | grep -qE "(security|auth|authentication|authorization|encryption|hash|password|token|jwt|oauth|vulnerability|scan)"; then
        echo "security"
        return 0
    fi
    
    # DevOps задачи
    if echo "$text_lower" | grep -qE "(deploy|ci|cd|docker|kubernetes|k8s|helm|ansible|terraform|infrastructure|pipeline|github actions|gitlab ci)"; then
        echo "orc_devops"
        return 0
    fi
    
    # Code quality задачи
    if echo "$text_lower" | grep -qE "(lint|format|quality|refactor|optimize|performance|benchmark)"; then
        echo "code-quality"
        return 0
    fi
    
    # Dependency задачи
    if echo "$text_lower" | grep -qE "(dependency|package|npm|pip|requirements|package.json|install|update|upgrade)"; then
        echo "dependency"
        return 0
    fi
    
    # По умолчанию - общая разработка
    echo "work_dev"
    return 0
}

# ============================================
# ФУНКЦИЯ: Поиск конкретного агента
# ============================================
find_specific_agent() {
    local agent_type="$1"
    local task_description="$2"
    
    # Дополнительные ключевые слова для уточнения
    local text_lower=$(echo "$task_description" | tr '[:upper:]' '[:lower:]')
    
    case "$agent_type" in
        "work_backend")
            if echo "$text_lower" | grep -qE "(api|endpoint|route|rest|graphql|websocket)"; then
                echo "work_backend_api_validator"
            elif echo "$text_lower" | grep -qE "(database|db|sql|model|migration|schema)"; then
                echo "work_backend_db_designer"
            elif echo "$text_lower" | grep -qE "(fastapi|django|flask|server)"; then
                echo "work_backend_developer"
            else
                echo "work_backend_api_validator"
            fi
            ;;
        
        "work_frontend")
            if echo "$text_lower" | grep -qE "(component|ui|view|jsx|tsx)"; then
                echo "work_frontend_component_generator"
            elif echo "$text_lower" | grep -qE "(style|css|bootstrap|material|layout)"; then
                echo "work_frontend_ui_coordinator"
            else
                echo "work_frontend_component_generator"
            fi
            ;;
        
        "work_testing")
            if echo "$text_lower" | grep -qE "(unit|mock|fixture)"; then
                echo "work_testing_unit_tester"
            elif echo "$text_lower" | grep -qE "(integration|e2e|end.*end)"; then
                echo "work_testing_integration_tester"
            elif echo "$text_lower" | grep -qE "(test|spec|coverage)"; then
                echo "work_testing_test_generator"
            else
                echo "work_testing_test_generator"
            fi
            ;;
        
        "security")
            if echo "$text_lower" | grep -qE "(scan|vulnerability|audit)"; then
                echo "security-analyzer"
            else
                echo "security-orchestrator"
            fi
            ;;
        
        "code-quality")
            echo "code-quality-checker"
            ;;
        
        "dependency")
            echo "dependency-analyzer"
            ;;
        
        "tech-translator-ru")
            echo "tech-translator-ru"
            ;;
        
        *)
            echo "work_dev_code_analyzer"
            ;;
    esac
}

# ============================================
# ОСНОВНОЙ ПРОЦЕСС: Анализ и назначение
# ============================================
log_info "Анализ задач и назначение агентов..."
echo ""

# Временный файл для обновлённых задач
TEMP_TASKS_FILE=$(mktemp)

# Счётчики
TOTAL_TASKS=0
ASSIGNED_TASKS=0
NEEDS_CREATION=0
SKIPPED_TASKS=0

# Массивы для отчёта
declare -a ASSIGNED_AGENTS=()
declare -a MISSING_AGENTS=()

# Чтение tasks.md построчно и обработка
CURRENT_TASK=""
CURRENT_DESC=""
IN_TASK=false

while IFS= read -r line || [ -n "$line" ]; do
    # Проверка на начало задачи (### T-XXX: или ### T-XXX)
    if echo "$line" | grep -qE "^### (T-[0-9]+:|T-[0-9]+)"; then
        # Если была предыдущая задача, записываем её
        if [ -n "$CURRENT_TASK" ]; then
            # Определение агента для предыдущей задачи
            AGENT_TYPE=$(determine_agent_type "$CURRENT_DESC" "$CURRENT_TASK")
            AGENT_NAME=$(find_specific_agent "$AGENT_TYPE" "$CURRENT_DESC")
            
            # Проверка существования агента
            if check_agent_exists "$AGENT_NAME"; then
                log_success "Задача: $CURRENT_TASK → Агент: $AGENT_NAME"
                ASSIGNED_TASKS=$((ASSIGNED_TASKS + 1))
                ASSIGNED_AGENTS+=("$AGENT_NAME")
                
                # Добавление агента в описание задачи
                echo "$LINE"
                echo "- **Агент:** $AGENT_NAME"
            else
                log_warning "Задача: $CURRENT_TASK → Агент не найден: $AGENT_NAME (помечено)"
                NEEDS_CREATION=$((NEEDS_CREATION + 1))
                MISSING_AGENTS+=("$AGENT_NAME")
                
                # Пометка отсутствующего агента
                echo "$LINE"
                echo "- **Агент:** [needs_creation:$AGENT_NAME]"
            fi
            
            ASSIGNED_TASKS=$((ASSIGNED_TASKS + 1))
        fi
        
        # Новая задача
        CURRENT_TASK=$(echo "$line" | sed 's/^### //' | sed 's/:.*//')
        CURRENT_DESC=""
        IN_TASK=true
        TOTAL_TASKS=$((TOTAL_TASKS + 1))
        
        echo "$line"
        continue
    fi
    
    # Если внутри задачи, собираем описание
    if [ "$IN_TASK" = true ]; then
        CURRENT_DESC="$CURRENT_DESC $line"
        
        # Проверка на строку с агентом (если уже есть)
        if echo "$line" | grep -qE "^\- \*\*Агент:\*\*"; then
            # Пропускаем, заменим позже
            continue
        fi
        
        echo "$line"
    else
        # Вне задач, копируем как есть
        echo "$line"
    fi
    
done < "$TASKS_FILE" > "$TEMP_TASKS_FILE"

# ============================================
# ЗАВЕРШЕНИЕ: Копирование и отчёт
# ============================================

# Копирование обновлённого файла
cp "$TEMP_TASKS_FILE" "$TASKS_FILE"
rm -f "$TEMP_TASKS_FILE"

# Создание отчёта
REPORT_FILE="$TMP_DIR/agent-assignment-report.json"
cat > "$REPORT_FILE" << EOF
{
  "timestamp": "$(date -Iseconds)",
  "spec_id": "$SPEC_ID",
  "summary": {
    "total_tasks": $TOTAL_TASKS,
    "assigned_tasks": $ASSIGNED_TASKS,
    "needs_creation": $NEEDS_CREATION
  },
  "assigned_agents": $(printf '%s\n' "${ASSIGNED_AGENTS[@]}" | sort -u | jq -R . | jq -s .),
  "missing_agents": $(printf '%s\n' "${MISSING_AGENTS[@]}" | sort -u | jq -R . | jq -s .)
}
EOF

# Вывод итогов
echo ""
log_header
echo "  Итоги назначения агентов"
log_header
echo ""
log_info "Всего задач: $TOTAL_TASKS"
log_success "Назначено агентов: $ASSIGNED_TASKS"

if [ "$NEEDS_CREATION" -gt 0 ]; then
    log_warning "Требуют создания: $NEEDS_CREATION"
    echo ""
    log_info "Отсутствующие агенты:"
    printf '%s\n' "${MISSING_AGENTS[@]}" | sort -u | while read -r agent; do
        echo "  - $agent"
    done
fi

echo ""
log_success "Отчёт сохранён: $REPORT_FILE"
log_success "tasks.md обновлён"
echo ""
log_success "Назначение агентов завершено успешно"
