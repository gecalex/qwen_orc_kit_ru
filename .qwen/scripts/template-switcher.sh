#!/bin/bash
# Скрипт: .qwen/scripts/template-switcher.sh
# Переключение между режимами шаблона: quickstart ↔ full

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
TEMPLATE_DIR="$PROJECT_ROOT/.qwen/template-cache"

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

# Проверка текущего режима
check_current_mode() {
    local agents_count=$(ls -1 "$PROJECT_ROOT/.qwen/agents/" 2>/dev/null | wc -l)
    
    if [ "$agents_count" -le 10 ]; then
        echo "quickstart"
    else
        echo "full"
    fi
}

# Сохранение текущих файлов перед переключением
backup_current_state() {
    local backup_dir="$PROJECT_ROOT/.qwen/.backup-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$backup_dir"
    
    log_info "Создание резервной копии в $backup_dir"
    
    # Копируем только пользовательские файлы
    cp -r "$PROJECT_ROOT/.qwen/agents/" "$backup_dir/agents/" 2>/dev/null || true
    cp -r "$PROJECT_ROOT/.qwen/skills/" "$backup_dir/skills/" 2>/dev/null || true
    cp -r "$PROJECT_ROOT/.qwen/commands/" "$backup_dir/commands/" 2>/dev/null || true
    
    log_success "Резервная копия создана"
    echo "$backup_dir"
}

# Загрузка шаблона из кэша или создание
ensure_template_cache() {
    if [ ! -d "$TEMPLATE_DIR" ]; then
        log_warning "Кэш шаблонов не найден. Создание..."
        mkdir -p "$TEMPLATE_DIR"
        
        # Копируем текущие файлы в кэш (полный шаблон)
        cp -r "$PROJECT_ROOT/.qwen/agents/" "$TEMPLATE_DIR/agents/" 2>/dev/null || true
        cp -r "$PROJECT_ROOT/.qwen/skills/" "$TEMPLATE_DIR/skills/" 2>/dev/null || true
        cp -r "$PROJECT_ROOT/.qwen/commands/" "$TEMPLATE_DIR/commands/" 2>/dev/null || true
        cp -r "$PROJECT_ROOT/.qwen/scripts/" "$TEMPLATE_DIR/scripts/" 2>/dev/null || true
        cp -r "$PROJECT_ROOT/.qwen/docs/" "$TEMPLATE_DIR/docs/" 2>/dev/null || true
        
        log_success "Кэш шаблонов создан"
    fi
}

# Переключение в режим быстрого старта
switch_to_quickstart() {
    log_info "Переключение в режим БЫСТРОГО СТАРТА..."
    
    # Создаем резервную копию
    local backup_dir=$(backup_current_state)
    
    # Оставляем только базовые компоненты
    
    # 1. Агенты (7 файлов)
    log_info "Настройка агентов (7 базовых)..."
    cd "$PROJECT_ROOT/.qwen/agents/"
    
    # Оставляем только базовые
    local keep_agents=(
        "orc_dev_task_coordinator.md"
        "orc_security_security_orchestrator.md"
        "orc_testing_quality_assurer.md"
        "work_dev_code_analyzer.md"
        "bug-fixer.md"
        "bug-hunter.md"
        "code-quality-checker.md"
    )
    
    # Удаляем все остальные
    for agent in *.md; do
        local found=false
        for keep in "${keep_agents[@]}"; do
            if [ "$agent" == "$keep" ]; then
                found=true
                break
            fi
        done
        if [ "$found" = false ]; then
            rm "$agent"
        fi
    done
    
    # 2. Навыки (10 файлов)
    log_info "Настройка навыков (10 базовых)..."
    cd "$PROJECT_ROOT/.qwen/skills/"
    
    local keep_skills=(
        "validate-report-file"
        "generate-report-header"
        "task-analyzer"
        "select-mcp-server"
        "security-analyzer"
        "dependency-auditor"
        "security-scanner"
        "bug-hunter"
        "bug-fixer"
        "run-quality-gate"
    )
    
    for skill_dir in */; do
        local skill_name="${skill_dir%/}"
        local found=false
        for keep in "${keep_skills[@]}"; do
            if [ "$skill_name" == "$keep" ]; then
                found=true
                break
            fi
        done
        if [ "$found" = false ]; then
            rm -rf "$skill_dir"
        fi
    done
    
    # 3. Команды (5 файлов)
    log_info "Настройка команд (5 базовых)..."
    cd "$PROJECT_ROOT/.qwen/commands/"
    
    local keep_commands=(
        "run-quality-gate.md"
        "health-security.md"
        "orchestrate-project.md"
        "template.md"
        "speckit.specify.md"
    )
    
    for cmd in *.md; do
        local found=false
        for keep in "${keep_commands[@]}"; do
            if [ "$cmd" == "$keep" ]; then
                found=true
                break
            fi
        done
        if [ "$found" = false ]; then
            rm "$cmd"
        fi
    done
    
    # 4. Скрипты (3 файла)
    log_info "Настройка скриптов (3 базовых)..."
    cd "$PROJECT_ROOT/.qwen/scripts/orchestration-tools/"
    
    # Оставляем только базовые
    ls *.sh | grep -v "analyze-project-state.sh" | grep -v "check-security.sh" | grep -v "health-bugs.sh" | xargs rm -f 2>/dev/null || true
    
    log_success "Режим БЫСТРОГО СТАРТА активирован"
    log_info "Резервная копия полных файлов: $backup_dir"
    log_warning "Для возврата используйте: $0 full"
}

# Переключение в полный режим
switch_to_full() {
    log_info "Переключение в режим ПОЛНЫЙ ШАБЛОН..."
    
    # Проверяем кэш
    ensure_template_cache
    
    # Восстанавливаем из кэша
    log_info "Восстановление полного шаблона из кэша..."
    
    # 1. Агенты
    if [ -d "$TEMPLATE_DIR/agents/" ]; then
        log_info "Восстановление агентов..."
        cp -r "$TEMPLATE_DIR/agents/"* "$PROJECT_ROOT/.qwen/agents/" 2>/dev/null || true
    fi
    
    # 2. Навыки
    if [ -d "$TEMPLATE_DIR/skills/" ]; then
        log_info "Восстановление навыков..."
        cp -r "$TEMPLATE_DIR/skills/"* "$PROJECT_ROOT/.qwen/skills/" 2>/dev/null || true
    fi
    
    # 3. Команды
    if [ -d "$TEMPLATE_DIR/commands/" ]; then
        log_info "Восстановление команд..."
        cp -r "$TEMPLATE_DIR/commands/"* "$PROJECT_ROOT/.qwen/commands/" 2>/dev/null || true
    fi
    
    # 4. Скрипты
    if [ -d "$TEMPLATE_DIR/scripts/" ]; then
        log_info "Восстановление скриптов..."
        cp -r "$TEMPLATE_DIR/scripts/"* "$PROJECT_ROOT/.qwen/scripts/" 2>/dev/null || true
    fi
    
    # 5. Документация
    if [ -d "$TEMPLATE_DIR/docs/" ]; then
        log_info "Восстановление документации..."
        cp -r "$TEMPLATE_DIR/docs/"* "$PROJECT_ROOT/.qwen/docs/" 2>/dev/null || true
    fi
    
    log_success "Режим ПОЛНЫЙ ШАБЛОН активирован"
}

# Показ статистики
show_stats() {
    echo ""
    log_info "📊 СТАТИСТИКА ПРОЕКТА"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    local agents=$(ls -1 "$PROJECT_ROOT/.qwen/agents/" 2>/dev/null | wc -l)
    local skills=$(ls -1 "$PROJECT_ROOT/.qwen/skills/" 2>/dev/null | wc -l)
    local commands=$(ls -1 "$PROJECT_ROOT/.qwen/commands/" 2>/dev/null | wc -l)
    local scripts=$(find "$PROJECT_ROOT/.qwen/scripts/" -name "*.sh" 2>/dev/null | wc -l)
    
    echo "  Агенты:    $agents"
    echo "  Навыки:    $skills"
    echo "  Команды:   $commands"
    echo "  Скрипты:   $scripts"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    if [ "$agents" -le 10 ]; then
        echo -e "  Режим: ${GREEN}БЫСТРЫЙ СТАРТ${NC}"
    else
        echo -e "  Режим: ${BLUE}ПОЛНЫЙ ШАБЛОН${NC}"
    fi
    echo ""
}

# Главная функция
main() {
    local mode="${1:-status}"
    
    case "$mode" in
        quickstart|qs|q)
            local current=$(check_current_mode)
            if [ "$current" == "quickstart" ]; then
                log_warning "Уже в режиме БЫСТРОГО СТАРТА"
                exit 0
            fi
            switch_to_quickstart
            show_stats
            ;;
        
        full|f)
            local current=$(check_current_mode)
            if [ "$current" == "full" ]; then
                log_warning "Уже в режиме ПОЛНОГО ШАБЛОНА"
                exit 0
            fi
            switch_to_full
            show_stats
            ;;
        
        status|s|stat)
            show_stats
            ;;
        
        help|h|-h|--help)
            echo "Использование: $0 [quickstart|full|status|help]"
            echo ""
            echo "Режимы:"
            echo "  quickstart, qs, q  - Переключиться на быстрый старт (7 агентов)"
            echo "  full, f            - Переключиться на полный шаблон (25 агентов)"
            echo "  status, s          - Показать текущий режим и статистику"
            echo "  help, h            - Показать эту справку"
            echo ""
            echo "Примеры:"
            echo "  $0 quickstart      - Включить быстрый старт"
            echo "  $0 full            - Включить полный шаблон"
            echo "  $0 status          - Проверить текущий режим"
            ;;
        
        *)
            log_error "Неизвестный режим: $mode"
            echo "Используйте '$0 help' для справки"
            exit 1
            ;;
    esac
}

# Запуск
main "$@"
