#!/bin/bash
#
# Component Linker
# Назначение: Автоматическая связь компонентов Qwen Code Orchestrator Kit
#
# Использование:
#   .qwen/integration/component-linker.sh [options]
#
# Options:
#   --analyze       Анализ зависимостей между компонентами
#   --find-missing  Выявление отсутствующих связей
#   --recommend     Генерация рекомендаций
#   --auto-link     Автоматическое создание связей (требует подтверждения)
#   --output FILE   Сохранить результат в файл
#   --verbose       Подробный вывод
#   --help          Показать справку
#

set -e

# Конфигурация
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
QWEN_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"
AGENTS_DIR="$QWEN_DIR/.qwen/agents"
SKILLS_DIR="$QWEN_DIR/.qwen/skills"
SCRIPTS_DIR="$QWEN_DIR/.qwen/scripts"
DOCS_DIR="$QWEN_DIR/.qwen/docs"
OUTPUT_FILE=""
VERBOSE=false
AUTO_LINK=false

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Структуры данных
declare -A COMPONENT_DEPENDENCIES
declare -A COMPONENT_USAGE
declare -a MISSING_LINKS
declare -a RECOMMENDATIONS

# Парсинг аргументов
ACTION="analyze"

while [[ $# -gt 0 ]]; do
    case $1 in
        --analyze)
            ACTION="analyze"
            shift
            ;;
        --find-missing)
            ACTION="find-missing"
            shift
            ;;
        --recommend)
            ACTION="recommend"
            shift
            ;;
        --auto-link)
            ACTION="auto-link"
            AUTO_LINK=true
            shift
            ;;
        --output)
            OUTPUT_FILE="$2"
            shift 2
            ;;
        --verbose)
            VERBOSE=true
            shift
            ;;
        --help)
            echo "Component Linker"
            echo ""
            echo "Использование:"
            echo "  $0 [options]"
            echo ""
            echo "Options:"
            echo "  --analyze       Анализ зависимостей между компонентами"
            echo "  --find-missing  Выявление отсутствующих связей"
            echo "  --recommend     Генерация рекомендаций"
            echo "  --auto-link     Автоматическое создание связей (требует подтверждения)"
            echo "  --output FILE   Сохранить результат в файл"
            echo "  --verbose       Подробный вывод"
            echo "  --help          Показать справку"
            exit 0
            ;;
        *)
            echo "Неизвестный параметр: $1"
            exit 1
            ;;
    esac
done

# Функция логирования
log() {
    local level="$1"
    local message="$2"
    
    case $level in
        INFO)
            echo -e "${BLUE}[INFO]${NC} $message"
            ;;
        SUCCESS)
            echo -e "${GREEN}[SUCCESS]${NC} $message"
            ;;
        WARNING)
            echo -e "${YELLOW}[WARNING]${NC} $message"
            ;;
        ERROR)
            echo -e "${RED}[ERROR]${NC} $message"
            ;;
        LINK)
            echo -e "${CYAN}[LINK]${NC} $message"
            ;;
        ANALYZE)
            echo -e "${MAGENTA}[ANALYZE]${NC} $message"
            ;;
    esac
}

# Функция извлечения ссылок на компоненты из файла
extract_component_refs() {
    local file="$1"
    local refs=()
    
    if [ -f "$file" ]; then
        # Поиск ссылок на оркестраторы
        while IFS= read -r line; do
            refs+=("$line")
        done < <(grep -oE 'orc_[a-z_]+' "$file" 2>/dev/null | sort -u)
        
        # Поиск ссылок на воркеры
        while IFS= read -r line; do
            refs+=("$line")
        done < <(grep -oE 'work_[a-z_]+' "$file" 2>/dev/null | sort -u)
        
        # Поиск ссылок на навыки
        while IFS= read -r line; do
            refs+=("$line")
        done < <(grep -oE 'skill:[a-z_-]+' "$file" 2>/dev/null | sort -u)
    fi
    
    echo "${refs[@]}"
}

# Функция анализа зависимостей оркестратора
analyze_orchestrator() {
    local file="$1"
    local name=$(basename "$file" .md)
    
    log "ANALYZE" "Analyzing orchestrator: $name"
    
    # Извлечение информации из YAML заголовка
    local domain=""
    local tools=""
    
    if [ -f "$file" ]; then
        domain=$(sed -n '/^---$/,/^---$/p' "$file" | grep "^domain:" | sed 's/domain: *//' | tr -d '"' || echo "")
        tools=$(sed -n '/^---$/,/^---$/p' "$file" | grep -A 100 "^tools:" | grep "^  -" | sed 's/  - //' || echo "")
    fi
    
    # Поиск используемых воркеров
    local workers_used=""
    if [ -f "$file" ]; then
        workers_used=$(grep -oE 'work_[a-z_]+' "$file" 2>/dev/null | sort -u | tr '\n' ' ' || echo "")
    fi
    
    # Поиск используемых навыков
    local skills_used=""
    if [ -f "$file" ]; then
        skills_used=$(grep -oE 'skill:[a-z_-]+' "$file" 2>/dev/null | sort -u | tr '\n' ' ' || echo "")
    fi
    
    # Сохранение зависимостей
    COMPONENT_DEPENDENCIES["$name"]="workers:$workers_used skills:$skills_used domain:$domain"
    
    if [ "$VERBOSE" = true ]; then
        echo "  Domain: $domain"
        echo "  Workers: $workers_used"
        echo "  Skills: $skills_used"
        echo ""
    fi
}

# Функция анализа зависимостей воркера
analyze_worker() {
    local file="$1"
    local name=$(basename "$file" .md)
    
    log "ANALYZE" "Analyzing worker: $name"
    
    # Извлечение информации из YAML заголовка
    local domain=""
    local tools=""
    
    if [ -f "$file" ]; then
        domain=$(sed -n '/^---$/,/^---$/p' "$file" | grep "^domain:" | sed 's/domain: *//' | tr -d '"' || echo "")
    fi
    
    # Поиск используемых навыков
    local skills_used=""
    if [ -f "$file" ]; then
        skills_used=$(grep -oE 'skill:[a-z_-]+' "$file" 2>/dev/null | sort -u | tr '\n' ' ' || echo "")
    fi
    
    # Сохранение зависимостей
    COMPONENT_DEPENDENCIES["$name"]="skills:$skills_used domain:$domain"
    
    if [ "$VERBOSE" = true ]; then
        echo "  Domain: $domain"
        echo "  Skills: $skills_used"
        echo ""
    fi
}

# Функция анализа всех компонентов
analyze_all_components() {
    log "INFO" "========================================"
    log "INFO" "  Component Dependency Analysis"
    log "INFO" "========================================"
    echo ""
    
    # Анализ оркестраторов
    log "INFO" "Scanning orchestrators..."
    if [ -d "$AGENTS_DIR" ]; then
        for file in "$AGENTS_DIR"/orc_*.md; do
            if [ -f "$file" ]; then
                analyze_orchestrator "$file"
            fi
        done
    fi
    
    # Анализ воркеров
    log "INFO" "Scanning workers..."
    if [ -d "$AGENTS_DIR" ]; then
        for file in "$AGENTS_DIR"/work_*.md; do
            if [ -f "$file" ]; then
                analyze_worker "$file"
            fi
        done
    fi
    
    log "SUCCESS" "Analysis complete. Found ${#COMPONENT_DEPENDENCIES[@]} components."
    echo ""
}

# Функция поиска отсутствующих связей
find_missing_links() {
    log "INFO" "========================================"
    log "INFO" "  Finding Missing Links"
    log "INFO" "========================================"
    echo ""
    
    MISSING_LINKS=()
    
    # Проверка что каждый оркестратор имеет соответствующих воркеров
    for component in "${!COMPONENT_DEPENDENCIES[@]}"; do
        local deps="${COMPONENT_DEPENDENCIES[$component]}"
        
        # Извлечение списка воркеров
        local workers=$(echo "$deps" | grep -oP 'workers:\K[^s]*' | xargs)
        
        for worker in $workers; do
            if [ -n "$worker" ]; then
                local worker_file="$AGENTS_DIR/$worker.md"
                if [ ! -f "$worker_file" ]; then
                    MISSING_LINKS+=("Orchestrator '$component' references non-existent worker '$worker'")
                    log "WARNING" "Missing worker: $worker (referenced by $component)"
                fi
            fi
        done
        
        # Извлечение списка навыков
        local skills=$(echo "$deps" | grep -oP 'skills:\K[^d]*' | xargs)
        
        for skill_ref in $skills; do
            local skill_name=$(echo "$skill_ref" | sed 's/skill://')
            if [ -n "$skill_name" ]; then
                local skill_dir="$SKILLS_DIR/$skill_name"
                if [ ! -d "$skill_dir" ]; then
                    MISSING_LINKS+=("Component '$component' references non-existent skill '$skill_name'")
                    log "WARNING" "Missing skill: $skill_name (referenced by $component)"
                fi
            fi
        done
    done
    
    # Проверка орфанных компонентов
    log "INFO" "Checking for orphaned components..."
    
    # Орфанные воркеры (не используются ни одним оркестратором)
    if [ -d "$AGENTS_DIR" ]; then
        for file in "$AGENTS_DIR"/work_*.md; do
            if [ -f "$file" ]; then
                local name=$(basename "$file" .md)
                local is_used=false
                
                for component in "${!COMPONENT_DEPENDENCIES[@]}"; do
                    local deps="${COMPONENT_DEPENDENCIES[$component]}"
                    if echo "$deps" | grep -q "$name"; then
                        is_used=true
                        break
                    fi
                done
                
                if [ "$is_used" = false ]; then
                    MISSING_LINKS+=("Worker '$name' is not used by any orchestrator")
                    log "WARNING" "Orphaned worker: $name"
                fi
            fi
        done
    fi
    
    echo ""
    log "INFO" "Found ${#MISSING_LINKS[@]} missing links."
    echo ""
}

# Функция генерации рекомендаций
generate_recommendations() {
    log "INFO" "========================================"
    log "INFO" "  Generating Recommendations"
    log "INFO" "========================================"
    echo ""
    
    RECOMMENDATIONS=()
    
    # Рекомендация 1: Группировка по доменам
    log "LINK" "Analyzing domain clustering..."
    declare -A domain_components
    
    for component in "${!COMPONENT_DEPENDENCIES[@]}"; do
        local deps="${COMPONENT_DEPENDENCIES[$component]}"
        local domain=$(echo "$deps" | grep -oP 'domain:\K[a-z]+' || echo "unknown")
        
        if [ -n "$domain" ]; then
            domain_components["$domain"]+="$component "
        fi
    done
    
    for domain in "${!domain_components[@]}"; do
        local components="${domain_components[$domain]}"
        local count=$(echo "$components" | wc -w)
        if [ $count -gt 3 ]; then
            RECOMMENDATIONS+=("Consider creating a domain-specific orchestrator for '$domain' (currently has $count components)")
            log "LINK" "Domain '$domain' has $count components - consider domain-specific orchestrator"
        fi
    done
    
    # Рекомендация 2: Общие навыки
    log "LINK" "Analyzing shared skills..."
    declare -A skill_usage
    
    for component in "${!COMPONENT_DEPENDENCIES[@]}"; do
        local deps="${COMPONENT_DEPENDENCIES[$component]}"
        local skills=$(echo "$deps" | grep -oP 'skills:\K[^d]*' | xargs)
        
        for skill in $skills; do
            skill_usage["$skill"]+="$component "
        done
    done
    
    for skill in "${!skill_usage[@]}"; do
        local users="${skill_usage[$skill]}"
        local count=$(echo "$users" | wc -w)
        if [ $count -gt 5 ]; then
            RECOMMENDATIONS+=("Skill '$skill' is heavily used ($count components) - ensure it's well-documented and tested")
            log "LINK" "Skill '$skill' is used by $count components"
        fi
    done
    
    # Рекомендация 3:Missing documentation links
    log "LINK" "Checking documentation coverage..."
    
    # Вывод рекомендаций
    echo ""
    log "INFO" "Generated ${#RECOMMENDATIONS[@]} recommendations:"
    echo ""
    
    for i in "${!RECOMMENDATIONS[@]}"; do
        echo "  $((i+1)). ${RECOMMENDATIONS[$i]}"
    done
    
    echo ""
}

# Функция автоматического линкинга
auto_link() {
    log "INFO" "========================================"
    log "INFO" "  Automatic Component Linking"
    log "INFO" "========================================"
    echo ""
    
    if [ "$AUTO_LINK" = false ]; then
        log "WARNING" "Auto-link mode not enabled. Use --auto-link to enable."
        return
    fi
    
    # Предупреждение перед автоматическими изменениями
    log "WARNING" "This will create link files between components."
    read -p "Continue? (y/N): " confirm
    
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        log "INFO" "Aborted by user."
        return
    fi
    
    local links_dir="$QWEN_DIR/integration/links"
    mkdir -p "$links_dir"
    
    local links_created=0
    
    # Создание файлов связей для каждого оркестратора
    for component in "${!COMPONENT_DEPENDENCIES[@]}"; do
        if [[ "$component" == orc_* ]]; then
            local deps="${COMPONENT_DEPENDENCIES[$component]}"
            local workers=$(echo "$deps" | grep -oP 'workers:\K[^s]*' | xargs)
            local skills=$(echo "$deps" | grep -oP 'skills:\K[^d]*' | xargs)
            
            local link_file="$links_dir/$component.links.json"
            
            cat > "$link_file" << EOF
{
  "component": "$component",
  "type": "orchestrator",
  "dependencies": {
    "workers": [$(echo "$workers" | sed 's/ /", "/g' | sed 's/^/"/' | sed 's/$/"/' | sed 's/""//')],
    "skills": [$(echo "$skills" | sed 's/skill://g' | sed 's/ /", "/g' | sed 's/^/"/' | sed 's/$/"/' | sed 's/""//')]
  },
  "generated": "$(date -Iseconds)"
}
EOF
            links_created=$((links_created + 1))
            log "SUCCESS" "Created link file: $link_file"
        fi
    done
    
    echo ""
    log "SUCCESS" "Created $links_created link files in $links_dir"
}

# Функция генерации отчета
generate_report() {
    local output=""
    
    output+="# Component Linker Report\n\n"
    output+="**Generated:** $(date '+%Y-%m-%d %H:%M:%S')\n\n"
    
    output+="## Component Dependencies\n\n"
    output+="| Component | Type | Domain | Workers | Skills |\n"
    output+="|-----------|------|--------|---------|--------|\n"
    
    for component in "${!COMPONENT_DEPENDENCIES[@]}"; do
        local deps="${COMPONENT_DEPENDENCIES[$component]}"
        local type="unknown"
        [[ "$component" == orc_* ]] && type="orchestrator"
        [[ "$component" == work_* ]] && type="worker"
        
        local domain=$(echo "$deps" | grep -oP 'domain:\K[a-z]+' || echo "-")
        local workers=$(echo "$deps" | grep -oP 'workers:\K[^s]*' | xargs | tr ' ' ',' || echo "-")
        local skills=$(echo "$deps" | grep -oP 'skills:\K[^d]*' | xargs | tr ' ' ',' || echo "-")
        
        output+="| $component | $type | $domain | $workers | $skills |\n"
    done
    
    output+="\n## Missing Links\n\n"
    if [ ${#MISSING_LINKS[@]} -eq 0 ]; then
        output+="No missing links detected.\n"
    else
        for link in "${MISSING_LINKS[@]}"; do
            output+="- ⚠️ $link\n"
        done
    fi
    
    output+="\n## Recommendations\n\n"
    if [ ${#RECOMMENDATIONS[@]} -eq 0 ]; then
        output+="No recommendations at this time.\n"
    else
        for i in "${!RECOMMENDATIONS[@]}"; do
            output+="$((i+1)). ${RECOMMENDATIONS[$i]}\n"
        done
    fi
    
    echo -e "$output"
}

# Основная функция
main() {
    log "INFO" "Component Linker v0.6.0"
    log "INFO" "Working directory: $QWEN_DIR"
    echo ""
    
    case $ACTION in
        analyze)
            analyze_all_components
            ;;
        find-missing)
            analyze_all_components
            find_missing_links
            ;;
        recommend)
            analyze_all_components
            find_missing_links
            generate_recommendations
            ;;
        auto-link)
            analyze_all_components
            find_missing_links
            generate_recommendations
            auto_link
            ;;
    esac
    
    # Генерация итогового отчета
    local report=$(generate_report)
    
    if [ -n "$OUTPUT_FILE" ]; then
        echo -e "$report" > "$OUTPUT_FILE"
        log "SUCCESS" "Report saved to: $OUTPUT_FILE"
    elif [ "$VERBOSE" = true ]; then
        echo ""
        echo "========================================"
        echo "  Full Report"
        echo "========================================"
        echo ""
        echo -e "$report"
    fi
}

# Запуск
main
