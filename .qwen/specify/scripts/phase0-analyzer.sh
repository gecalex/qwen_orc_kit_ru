#!/bin/bash
# Скрипт: .qwen/specify/scripts/phase0-analyzer.sh
# Назначение: Анализ задач спецификации и создание плана Фазы 0
# Интеграция: .qwen/specify/specs/{ID}-{feature}/

set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Логирование
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Проверка аргументов
SPEC_DIR="$1"

if [ -z "$SPEC_DIR" ]; then
    log_error "Использование: $0 <путь-к-спецификации>"
    log_info "Пример: $0 .qwen/specify/specs/001-user-auth"
    exit 1
fi

SPEC_FILE="$SPEC_DIR/spec.md"
TASKS_FILE="$SPEC_DIR/tasks.md"

# Проверка наличия спецификации
if [ ! -f "$SPEC_FILE" ]; then
    log_error "Спецификация не найдена: $SPEC_FILE"
    exit 1
fi

log_success "Спецификация найдена: $SPEC_FILE"

# Проверка наличия tasks.md (если уже создан)
if [ -f "$TASKS_FILE" ]; then
    log_success "tasks.md найден: $TASKS_FILE"
    TASKS_EXIST=true
else
    log_warning "tasks.md еще не создан (будет создан через speckit.tasks)"
    TASKS_EXIST=false
fi

# Создание директории для планов
PLAN_DIR="$SPEC_DIR/plans"
mkdir -p "$PLAN_DIR"
log_info "Создана директория для планов: $PLAN_DIR"

# Анализ задач из спецификации
log_info "🔍 Анализ задач..."

if [ "$TASKS_EXIST" = true ]; then
    # Подсчет задач из tasks.md
    TOTAL_TASKS=$(grep -c "^\- \[" "$TASKS_FILE" 2>/dev/null || echo 0)
    COMPLETED_TASKS=$(grep -c "^\- \[X\]" "$TASKS_FILE" 2>/dev/null || echo 0)
    PENDING_TASKS=$(grep -c "^\- \[ \]" "$TASKS_FILE" 2>/dev/null || echo 0)
    
    log_success "Найдено задач: $TOTAL_TASKS (выполнено: $COMPLETED_TASKS, осталось: $PENDING_TASKS)"
else
    # Подсчет требований из spec.md
    REQUIREMENTS=$(grep -c "## [0-9]\+\." "$SPEC_FILE" 2>/dev/null || echo 0)
    log_success "Найдено разделов требований: $REQUIREMENTS"
    TOTAL_TASKS=$REQUIREMENTS
fi

# Анализ доменов задачи
log_info "🌐 Анализ доменов задачи..."

# Извлечение функциональных требований и определение доменов
BACKEND_TASKS=0
FRONTEND_TASKS=0
TESTING_TASKS=0
DOC_TASKS=0

if [ "$TASKS_EXIST" = true ]; then
    BACKEND_TASKS=$(grep -ci "backend\|api\|database\|сервер\|баз.*данных" "$TASKS_FILE" 2>/dev/null || echo 0)
    FRONTEND_TASKS=$(grep -ci "frontend\|ui\|interface\|компонент\|пользователь" "$TASKS_FILE" 2>/dev/null || echo 0)
    TESTING_TASKS=$(grep -ci "test\|тест\|проверк\|validate" "$TASKS_FILE" 2>/dev/null || echo 0)
    DOC_TASKS=$(grep -ci "doc\|документ\|перевод\|translate" "$TASKS_FILE" 2>/dev/null || echo 0)
fi

log_info "Домены: backend=$BACKEND_TASKS, frontend=$FRONTEND_TASKS, testing=$TESTING_TASKS, docs=$DOC_TASKS"

# Определение требуемых агентов
log_info "🤖 Определение требуемых агентов..."

AGENTS_FILE="$PLAN_DIR/phase0-agents.json"

# Определение оркестраторов
ORCHESTRATORS="["
if [ $BACKEND_TASKS -gt 0 ]; then
    ORCHESTRATORS="$ORCHESTRATORS\"orc_backend_api_coordinator\","
fi
if [ $FRONTEND_TASKS -gt 0 ]; then
    ORCHESTRATORS="$ORCHESTRATORS\"orc_frontend_ui_coordinator\","
fi
if [ $TESTING_TASKS -gt 0 ]; then
    ORCHESTRATORS="$ORCHESTRATORS\"orc_testing_quality_assurer\","
fi
# Всегда добавляем dev_task_coordinator
ORCHESTRATORS="$ORCHESTRATORS\"orc_dev_task_coordinator\""
ORCHESTRATORS="$ORCHESTRATORS]"

# Определение воркеров
WORKERS="["
if [ $BACKEND_TASKS -gt 0 ]; then
    WORKERS="$WORKERS\"work_backend_api_validator\","
fi
if [ $FRONTEND_TASKS -gt 0 ]; then
    WORKERS="$WORKERS\"work_frontend_component_generator\","
fi
if [ $TESTING_TASKS -gt 0 ]; then
    WORKERS="$WORKERS\"work_testing_test_generator\",\"work_testing_code_quality_checker\","
fi
# Всегда добавляем базовых
WORKERS="$WORKERS\"work_dev_code_analyzer\",\"bug-hunter\",\"bug-fixer\""
WORKERS="$WORKERS]"

# Создание файла агентов
cat > "$AGENTS_FILE" << EOF
{
  "specification": "$SPEC_FILE",
  "analyzedAt": "$(date -Iseconds)",
  "taskStatistics": {
    "total": $TOTAL_TASKS,
    "backend": $BACKEND_TASKS,
    "frontend": $FRONTEND_TASKS,
    "testing": $TESTING_TASKS,
    "documentation": $DOC_TASKS
  },
  "requiredAgents": {
    "orchestrators": $ORCHESTRATORS,
    "workers": $WORKERS
  },
  "missingAgents": [],
  "mcpRecommendations": [
    "mcp__context7__*",
    "mcp__filesystem__*",
    "mcp__git__*"
  ]
}
EOF

log_success "Анализ агентов создан: $AGENTS_FILE"

# Создание плана Фазы 0
log_info "📋 Создание плана Фазы 0..."

PLAN_FILE="$PLAN_DIR/phase0-plan.json"

# Определение приоритета
PRIORITY="high"
if [ $TOTAL_TASKS -lt 5 ]; then
    PRIORITY="medium"
elif [ $TOTAL_TASKS -lt 10 ]; then
    PRIORITY="high"
else
    PRIORITY="critical"
fi

# Создание плана
cat > "$PLAN_FILE" << EOF
{
  "phase": 0,
  "specification": "$SPEC_FILE",
  "createdAt": "$(date -Iseconds)",
  "status": "initialized",
  "config": {
    "priority": "$PRIORITY",
    "scope": ["$SPEC_DIR"],
    "estimatedTasks": $TOTAL_TASKS
  },
  "validation": {
    "required": ["task-analysis", "agent-determination"],
    "optional": ["mcp-recommendations"]
  },
  "mcpGuidance": {
    "recommended": ["mcp__context7__*", "mcp__filesystem__*", "mcp__git__*"],
    "library": "planning",
    "reason": "Проверка текущих шаблонов планирования перед реализацией"
  },
  "nextAgent": "orc_planning_task_analyzer",
  "gates": {
    "gate0": {
      "name": "Pre-Planning Gate",
      "status": "pending",
      "script": ".qwen/scripts/quality-gates/check-planning.sh"
    },
    "gate1": {
      "name": "Planning Quality Gate",
      "status": "pending",
      "script": ".qwen/scripts/quality-gates/check-planning.sh"
    }
  }
}
EOF

log_success "План Фазы 0 создан: $PLAN_FILE"

# Создание файла назначений (заготовка)
ASSIGNMENTS_FILE="$PLAN_DIR/phase0-assignments.json"

cat > "$ASSIGNMENTS_FILE" << EOF
{
  "specification": "$SPEC_FILE",
  "createdAt": "$(date -Iseconds)",
  "status": "pending",
  "assignments": [],
  "notes": "Назначения будут созданы через orc_planning_task_analyzer"
}
EOF

log_info "Создан файл назначений: $ASSIGNMENTS_FILE"

# ============================================================================
# УВЕДОМЛЕНИЯ О ПОСТФАКТУМ АГЕНТАХ
# ============================================================================
log_info "Проверка постфактум агентов..."

# Проверка: все ли агенты из плана существуют
MISSING_AGANTS=0
if [ -f "$AGENTS_FILE" ]; then
    # Извлечь требуемых агентов из плана
    REQUIRED_AGENTS=$(grep -o '"work_[^"]*"' "$AGENTS_FILE" 2>/dev/null | sort -u | wc -l)
    
    # Проверить наличие в .qwen/agents/
    for agent in $(grep -o '"work_[^"]*"' "$AGENTS_FILE" 2>/dev/null | tr -d '"'); do
        if [ ! -f ".qwen/agents/${agent}.md" ]; then
            log_warning "Агент отсутствует: $agent"
            MISSING_AGANTS=$((MISSING_AGANTS + 1))
        fi
    done
    
    if [ $MISSING_AGANTS -gt 0 ]; then
        echo ""
        log_warning "Обнаружено отсутствующих агентов: $MISSING_AGANTS"
        log_info "Создайте агентов через:"
        echo "  task '{"
        echo "    \"subagent_type\": \"work_dev_meta_agent\","
        echo "    \"description\": \"Создать отсутствующих агентов\","
        echo "    \"prompt\": \"Создать агентов: <список>\""
        echo "  }'"
        echo ""
        log_info "Или вручную:"
        echo "  cp .qwen/templates/worker-template.md .qwen/agents/<agent-name>.md"
        echo ""
    else
        log_success "Все требуемые агенты существуют"
    fi
fi

# Финальный отчет
echo ""
log_success "=== Фаза 0: Анализ завершен ==="
echo ""
echo "📊 Статистика:"
echo "  Всего задач: $TOTAL_TASKS"
echo "  Backend: $BACKEND_TASKS"
echo "  Frontend: $FRONTEND_TASKS"
echo "  Testing: $TESTING_TASKS"
echo "  Documentation: $DOC_TASKS"
echo "  Приоритет: $PRIORITY"
if [ $MISSING_AGANTS -gt 0 ]; then
    echo "  ⚠️  Отсутствуют агенты: $MISSING_AGANTS"
fi
echo ""
echo "📁 Созданные файлы:"
echo "  - $PLAN_FILE"
echo "  - $AGENTS_FILE"
echo "  - $ASSIGNMENTS_FILE"
echo ""
echo "🔄 Следующий шаг:"
echo "  Запустите: orc_planning_task_analyzer"
echo "  Для назначения исполнителей на задачи"
echo ""

# Вывод JSON для использования в скриптах
echo "📄 JSON план:"
cat "$PLAN_FILE"

exit 0
