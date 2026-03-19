#!/bin/bash
# Скрипт: .qwen/scripts/orchestration-tools/pre-flight-check.sh
# Назначение: Pre-Flight проверки перед началом фазы разработки
# Блокирующая: true (останавливает процесс при неудаче)

set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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
PHASE_NAME="${1:-Фаза}"

log_info "=== Pre-Flight Проверки: $PHASE_NAME ==="
log_info "Дата: $(date '+%Y-%m-%d %H:%M:%S')"

ERRORS=0
WARNINGS=0

# ============================================================================
# ПРОВЕРКА 1: Git репозиторий
# ============================================================================
log_info "Проверка 1: Git репозиторий..."

if [ ! -d ".git" ]; then
    log_error "Git репозиторий не инициализирован"
    log_info "Инициализируйте: git init"
    ERRORS=$((ERRORS + 1))
else
    log_success "Git репозиторий инициализирован"
    
    # Проверка текущей ветки
    CURRENT_BRANCH=$(git branch --show-current)
    if [ "$CURRENT_BRANCH" = "main" ]; then
        log_warning "Разработка в ветке main не рекомендуется"
        log_info "Создайте ветку: git checkout -b develop"
        WARNINGS=$((WARNINGS + 1))
    else
        log_success "Текущая ветка: $CURRENT_BRANCH"
    fi
fi

# ============================================================================
# ПРОВЕРКА 2: Ветка develop
# ============================================================================
log_info "Проверка 2: Ветка develop..."

if ! git branch | grep -q "develop"; then
    log_warning "Ветка develop отсутствует"
    log_info "Создайте: git branch develop"
    WARNINGS=$((WARNINGS + 1))
else
    log_success "Ветка develop существует"
fi

# ============================================================================
# ПРОВЕРКА 3: .gitignore
# ============================================================================
log_info "Проверка 3: Файл .gitignore..."

if [ ! -f ".gitignore" ]; then
    log_error ".gitignore отсутствует"
    log_info "Создайте .gitignore для игнорирования временных файлов"
    ERRORS=$((ERRORS + 1))
else
    log_success ".gitignore существует"
    
    # Проверка наличия state/ в .gitignore
    if ! grep -q "^state/" .gitignore 2>/dev/null; then
        log_warning "state/ не в .gitignore (рекомендуется добавить)"
        WARNINGS=$((WARNINGS + 1))
    fi
fi

# ============================================================================
# ПРОВЕРКА 4: Конституция проекта
# ============================================================================
log_info "Проверка 4: Конституция проекта..."

CONSTITUTION_FILE=".qwen/specify/memory/constitution.md"

if [ ! -f "$CONSTITUTION_FILE" ]; then
    log_error "constitution.md отсутствует"
    log_info "Создайте через: speckit.constitution"
    ERRORS=$((ERRORS + 1))
else
    log_success "Конституция проекта существует"
fi

# ============================================================================
# ПРОВЕРКА 5: Quality Gates скрипты
# ============================================================================
log_info "Проверка 5: Quality Gates скрипты..."

GATES_DIR=".qwen/scripts/quality-gates"
GATES_COUNT=0

if [ ! -d "$GATES_DIR" ]; then
    log_error "Директория Quality Gates отсутствует"
    ERRORS=$((ERRORS + 1))
else
    # Проверка основных скриптов
    GATES=(
        "check-planning.sh"
        "check-specifications.sh"
        "check-security.sh"
        "check-coverage.sh"
        "check-bundle-size.sh"
    )
    
    for gate in "${GATES[@]}"; do
        if [ -f "$GATES_DIR/$gate" ]; then
            GATES_COUNT=$((GATES_COUNT + 1))
        else
            log_warning "Отсутствует: $gate"
            WARNINGS=$((WARNINGS + 1))
        fi
    done
    
    log_success "Quality Gates скрипты: $GATES_COUNT/${#GATES[@]}"
fi

# ============================================================================
# ПРОВЕРКА 6: Агенты
# ============================================================================
log_info "Проверка 6: Агенты..."

AGENTS_DIR=".qwen/agents"

if [ ! -d "$AGENTS_DIR" ]; then
    log_error "Директория агентов отсутствует"
    ERRORS=$((ERRORS + 1))
else
    AGENTS_COUNT=$(ls -1 "$AGENTS_DIR"/*.md 2>/dev/null | wc -l)
    
    if [ "$AGENTS_COUNT" -lt 7 ]; then
        log_warning "Мало агентов: $AGENTS_COUNT (рекомендуется >= 7)"
        WARNINGS=$((WARNINGS + 1))
    else
        log_success "Агенты: $AGENTS_COUNT файлов"
    fi
fi

# ============================================================================
# ПРОВЕРКА 7: Speckit команды
# ============================================================================
log_info "Проверка 7: Speckit команды..."

COMMANDS_DIR=".qwen/commands"

if [ ! -d "$COMMANDS_DIR" ]; then
    log_error "Директория команд отсутствует"
    ERRORS=$((ERRORS + 1))
else
    SPECKIT_COUNT=$(ls -1 "$COMMANDS_DIR"/speckit.*.md 2>/dev/null | wc -l)
    
    if [ "$SPECKIT_COUNT" -lt 9 ]; then
        log_warning "Мало Speckit команд: $SPECKIT_COUNT (рекомендуется 9)"
        WARNINGS=$((WARNINGS + 1))
    else
        log_success "Speckit команды: $SPECKIT_COUNT файлов"
    fi
fi

# ============================================================================
# ПРОВЕРКА 8: Skills
# ============================================================================
log_info "Проверка 8: Навыки (Skills)..."

SKILLS_DIR=".qwen/skills"

if [ ! -d "$SKILLS_DIR" ]; then
    log_error "Директория навыков отсутствует"
    ERRORS=$((ERRORS + 1))
else
    SKILLS_COUNT=$(find "$SKILLS_DIR" -name "SKILL.md" 2>/dev/null | wc -l)
    
    if [ "$SKILLS_COUNT" -lt 10 ]; then
        log_warning "Мало навыков: $SKILLS_COUNT (рекомендуется >= 10)"
        WARNINGS=$((WARNINGS + 1))
    else
        log_success "Навыки: $SKILLS_COUNT файлов"
    fi
fi

# ============================================================================
# ПРОВЕРКА 9: MCP конфигурация
# ============================================================================
log_info "Проверка 9: MCP конфигурация..."

MCP_FILE=".qwen/mcp.json"

if [ ! -f "$MCP_FILE" ]; then
    log_warning "MCP конфигурация отсутствует"
    log_info "Создайте .qwen/mcp.json для интеграции с MCP серверами"
    WARNINGS=$((WARNINGS + 1))
else
    log_success "MCP конфигурация существует"
fi

# ============================================================================
# ПРОВЕРКА 10: Scripts
# ============================================================================
log_info "Проверка 10: Скрипты..."

SCRIPTS_DIR=".qwen/scripts"

if [ ! -d "$SCRIPTS_DIR" ]; then
    log_error "Директория скриптов отсутствует"
    ERRORS=$((ERRORS + 1))
else
    SCRIPTS_COUNT=$(find "$SCRIPTS_DIR" -name "*.sh" 2>/dev/null | wc -l)
    
    if [ "$SCRIPTS_COUNT" -lt 5 ]; then
        log_warning "Мало скриптов: $SCRIPTS_COUNT (рекомендуется >= 5)"
        WARNINGS=$((WARNINGS + 1))
    else
        log_success "Скрипты: $SCRIPTS_COUNT файлов"
    fi
fi

# ============================================================================
# ФИНАЛЬНЫЙ ОТЧЕТ
# ============================================================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_info "Результаты Pre-Flight проверок:"
echo ""
echo "  ✅ Успешно: $((10 - ERRORS - WARNINGS))"
echo "  ⚠️  Предупреждения: $WARNINGS"
echo "  ❌ Ошибки: $ERRORS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ $ERRORS -gt 0 ]; then
    echo ""
    log_error "Pre-Flight проверки НЕ ПРОЙДЕНЫ ($ERRORS ошибок)"
    echo ""
    log_info "Необходимо устранить ошибки перед продолжением:"
    
    if [ ! -d ".git" ]; then
        echo "  1. Инициализируйте Git: git init"
    fi
    
    if [ ! -f ".gitignore" ]; then
        echo "  2. Создайте .gitignore"
    fi
    
    if [ ! -f "$CONSTITUTION_FILE" ]; then
        echo "  3. Создайте конституцию: speckit.constitution"
    fi
    
    if [ ! -d "$AGENTS_DIR" ]; then
        echo "  4. Создайте директорию агентов"
    fi
    
    if [ ! -d "$COMMANDS_DIR" ]; then
        echo "  5. Создайте директорию команд"
    fi
    
    if [ ! -d "$SKILLS_DIR" ]; then
        echo "  6. Создайте директорию навыков"
    fi
    
    echo ""
    exit 1
fi

if [ $WARNINGS -gt 0 ]; then
    echo ""
    log_warning "Pre-Flight проверки пройдены с предупреждениями ($WARNINGS)"
    log_info "Рекомендуется устранить предупреждения для оптимальной работы"
    echo ""
else
    echo ""
    log_success "Pre-Flight проверки ПРОЙДЕНЫ ✅"
    echo ""
    log_info "Следующий шаг: Начало $PHASE_NAME"
    echo ""
fi

exit 0
