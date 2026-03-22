#!/bin/bash
#
# Component Registry Scanner
# Назначение: Реестр всех компонентов системы Qwen Code Orchestrator Kit
#
# Использование:
#   .qwen/integration/component-registry.sh [options]
#
# Options:
#   --json          Вывод в формате JSON (по умолчанию)
#   --markdown      Вывод в формате Markdown
#   --verbose       Подробный вывод с описанием компонентов
#   --output FILE   Сохранить результат в файл
#   --help          Показать справку
#

set -e

# Конфигурация
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
QWEN_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"
AGENTS_DIR="$QWEN_DIR/.qwen/agents"
SKILLS_DIR="$QWEN_DIR/.qwen/skills"
COMMANDS_DIR="$QWEN_DIR/.qwen/commands"
SCRIPTS_DIR="$QWEN_DIR/.qwen/scripts"
OUTPUT_FORMAT="json"
OUTPUT_FILE=""
VERBOSE=false

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Парсинг аргументов
while [[ $# -gt 0 ]]; do
    case $1 in
        --json)
            OUTPUT_FORMAT="json"
            shift
            ;;
        --markdown)
            OUTPUT_FORMAT="markdown"
            shift
            ;;
        --verbose)
            VERBOSE=true
            shift
            ;;
        --output)
            OUTPUT_FILE="$2"
            shift 2
            ;;
        --help)
            echo "Component Registry Scanner"
            echo ""
            echo "Использование:"
            echo "  $0 [options]"
            echo ""
            echo "Options:"
            echo "  --json          Вывод в формате JSON (по умолчанию)"
            echo "  --markdown      Вывод в формате Markdown"
            echo "  --verbose       Подробный вывод с описанием компонентов"
            echo "  --output FILE   Сохранить результат в файл"
            echo "  --help          Показать справку"
            exit 0
            ;;
        *)
            echo "Неизвестный параметр: $1"
            exit 1
            ;;
    esac
done

# Функция для подсчета файлов в директории
count_files() {
    local dir="$1"
    local pattern="${2:-*}"
    if [ -d "$dir" ]; then
        find "$dir" -maxdepth 1 -name "$pattern" -type f 2>/dev/null | wc -l
    else
        echo "0"
    fi
}

# Функция для подсчета поддиректорий
count_dirs() {
    local dir="$1"
    if [ -d "$dir" ]; then
        find "$dir" -maxdepth 1 -mindepth 1 -type d 2>/dev/null | wc -l
    else
        echo "0"
    fi
}

# Функция для извлечения имени из файла агента
extract_agent_name() {
    local file="$1"
    basename "$file" .md
}

# Функция для извлечения описания из YAML заголовка агента
extract_agent_description() {
    local file="$1"
    if [ -f "$file" ]; then
        # Извлекаем описание из YAML заголовка
        sed -n '/^---$/,/^---$/p' "$file" | grep "^description:" | sed 's/description: *//' | tr -d '"' || echo "No description"
    else
        echo "File not found"
    fi
}

# Функция для извлечения типа агента (orchestrator/worker)
extract_agent_type() {
    local file="$1"
    local name=$(basename "$file" .md)
    if [[ "$name" == orc_* ]]; then
        echo "orchestrator"
    elif [[ "$name" == work_* ]]; then
        echo "worker"
    else
        echo "unknown"
    fi
}

# Функция для извлечения домена агента
extract_agent_domain() {
    local file="$1"
    local name=$(basename "$file" .md)
    # Извлекаем домен из имени (вторая часть после префикса)
    echo "$name" | cut -d'_' -f2
}

# Функция для сканирования агентов
scan_agents() {
    local agents=()
    local orchestrators=()
    local workers=()
    
    if [ -d "$AGENTS_DIR" ]; then
        for file in "$AGENTS_DIR"/*.md; do
            if [ -f "$file" ]; then
                local name=$(extract_agent_name "$file")
                local type=$(extract_agent_type "$file")
                local domain=$(extract_agent_domain "$file")
                local desc=""
                
                if [ "$VERBOSE" = true ]; then
                    desc=$(extract_agent_description "$file")
                fi
                
                agents+=("$name")
                
                if [ "$type" == "orchestrator" ]; then
                    orchestrators+=("$name")
                elif [ "$type" == "worker" ]; then
                    workers+=("$name")
                fi
            fi
        done
    fi
    
    echo "${#agents[@]}:${#orchestrators[@]}:${#workers[@]}"
}

# Функция для сканирования навыков
scan_skills() {
    local count=0
    if [ -d "$SKILLS_DIR" ]; then
        count=$(count_dirs "$SKILLS_DIR")
    fi
    echo "$count"
}

# Функция для сканирования команд
scan_commands() {
    local count=0
    if [ -d "$COMMANDS_DIR" ]; then
        count=$(count_files "$COMMANDS_DIR" "*.sh")
    fi
    echo "$count"
}

# Функция для сканирования скриптов
scan_scripts() {
    local count=0
    if [ -d "$SCRIPTS_DIR" ]; then
        # Считаем все .sh файлы рекурсивно
        count=$(find "$SCRIPTS_DIR" -name "*.sh" -type f 2>/dev/null | wc -l)
    fi
    echo "$count"
}

# Функция для генерации JSON вывода
generate_json() {
    local agents_result=$(scan_agents)
    local total_agents=$(echo "$agents_result" | cut -d':' -f1)
    local orchestrators=$(echo "$agents_result" | cut -d':' -f2)
    local workers=$(echo "$agents_result" | cut -d':' -f3)
    
    local skills=$(scan_skills)
    local commands=$(scan_commands)
    local scripts=$(scan_scripts)
    local total=$((total_agents + skills + commands + scripts))
    
    # Получаем списки агентов для детального вывода
    local orchestrator_list=""
    local worker_list=""
    
    if [ -d "$AGENTS_DIR" ]; then
        for file in "$AGENTS_DIR"/*.md; do
            if [ -f "$file" ]; then
                local name=$(extract_agent_name "$file")
                local type=$(extract_agent_type "$file")
                if [ "$type" == "orchestrator" ]; then
                    [ -n "$orchestrator_list" ] && orchestrator_list+=","
                    orchestrator_list+="\"$name\""
                elif [ "$type" == "worker" ]; then
                    [ -n "$worker_list" ] && worker_list+=","
                    worker_list+="\"$name\""
                fi
            fi
        done
    fi
    
    # Получаем список навыков
    local skills_list=""
    if [ -d "$SKILLS_DIR" ]; then
        for dir in "$SKILLS_DIR"/*/; do
            if [ -d "$dir" ]; then
                local name=$(basename "$dir")
                [ -n "$skills_list" ] && skills_list+=","
                skills_list+="\"$name\""
            fi
        done
    fi
    
    cat << EOF
{
  "timestamp": "$(date -Iseconds)",
  "version": "0.6.0",
  "summary": {
    "orchestrators": $orchestrators,
    "workers": $workers,
    "agents_total": $total_agents,
    "skills": $skills,
    "commands": $commands,
    "scripts": $scripts,
    "total_components": $total
  },
  "components": {
    "orchestrators": [$orchestrator_list],
    "workers": [$worker_list],
    "skills": [$skills_list]
  },
  "directories": {
    "agents": "$AGENTS_DIR",
    "skills": "$SKILLS_DIR",
    "commands": "$COMMANDS_DIR",
    "scripts": "$SCRIPTS_DIR"
  }
}
EOF
}

# Функция для генерации Markdown вывода
generate_markdown() {
    local agents_result=$(scan_agents)
    local total_agents=$(echo "$agents_result" | cut -d':' -f1)
    local orchestrators=$(echo "$agents_result" | cut -d':' -f2)
    local workers=$(echo "$agents_result" | cut -d':' -f3)
    
    local skills=$(scan_skills)
    local commands=$(scan_commands)
    local scripts=$(scan_scripts)
    local total=$((total_agents + skills + commands + scripts))
    
    cat << EOF
# Component Registry

**Generated:** $(date '+%Y-%m-%d %H:%M:%S')  
**Version:** 0.6.0

## Summary

| Component Type | Count |
|----------------|-------|
| Orchestrators  | $orchestrators |
| Workers        | $workers |
| **Agents Total** | **$total_agents** |
| Skills         | $skills |
| Commands       | $commands |
| Scripts        | $scripts |
| **Total**      | **$total** |

EOF

    if [ "$VERBOSE" = true ]; then
        echo "## Orchestrators"
        echo ""
        echo "| Name | Domain | Description |"
        echo "|------|--------|-------------|"
        
        if [ -d "$AGENTS_DIR" ]; then
            for file in "$AGENTS_DIR"/*.md; do
                if [ -f "$file" ]; then
                    local name=$(extract_agent_name "$file")
                    if [[ "$name" == orc_* ]]; then
                        local domain=$(extract_agent_domain "$file")
                        local desc=$(extract_agent_description "$file" | cut -c1-50)
                        echo "| $name | $domain | $desc |"
                    fi
                fi
            done
        fi
        
        echo ""
        echo "## Workers"
        echo ""
        echo "| Name | Domain | Description |"
        echo "|------|--------|-------------|"
        
        if [ -d "$AGENTS_DIR" ]; then
            for file in "$AGENTS_DIR"/*.md; do
                if [ -f "$file" ]; then
                    local name=$(extract_agent_name "$file")
                    if [[ "$name" == work_* ]]; then
                        local domain=$(extract_agent_domain "$file")
                        local desc=$(extract_agent_description "$file" | cut -c1-50)
                        echo "| $name | $domain | $desc |"
                    fi
                fi
            done
        fi
        
        echo ""
        echo "## Skills"
        echo ""
        
        if [ -d "$SKILLS_DIR" ]; then
            for dir in "$SKILLS_DIR"/*/; do
                if [ -d "$dir" ]; then
                    local name=$(basename "$dir")
                    echo "- \`$name\`"
                fi
            done
        fi
    fi
}

# Основная функция
main() {
    echo -e "${BLUE}=== Component Registry Scanner ===${NC}" >&2
    echo -e "${BLUE}Scanning: $QWEN_DIR${NC}" >&2
    echo "" >&2
    
    # Проверка существования директорий
    for dir in "$AGENTS_DIR" "$SKILLS_DIR" "$COMMANDS_DIR" "$SCRIPTS_DIR"; do
        if [ -d "$dir" ]; then
            echo -e "${GREEN}✓${NC} $dir" >&2
        else
            echo -e "${YELLOW}!${NC} $dir (not found)" >&2
        fi
    done
    echo "" >&2
    
    # Генерация вывода
    local output=""
    if [ "$OUTPUT_FORMAT" == "json" ]; then
        output=$(generate_json)
    else
        output=$(generate_markdown)
    fi
    
    # Вывод результата
    if [ -n "$OUTPUT_FILE" ]; then
        echo "$output" > "$OUTPUT_FILE"
        echo -e "${GREEN}✓${NC} Registry saved to: $OUTPUT_FILE" >&2
    else
        echo "$output"
    fi
    
    echo "" >&2
    echo -e "${GREEN}=== Scan Complete ===${NC}" >&2
}

# Запуск
main
