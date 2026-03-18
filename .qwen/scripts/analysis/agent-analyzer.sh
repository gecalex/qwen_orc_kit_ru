#!/bin/bash
# Скрипт анализа агентов для обновления индекса
# Назначение: Анализ файлов агентов и извлечение метаданных для индексации

set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Функция для вывода сообщений
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

AGENTS_DIR=".qwen/agents"
OUTPUT_FILE="reports/agent-analysis-report.md"

log_info "Начало анализа агентов в директории: $AGENTS_DIR"

# Проверяем, существует ли директория с агентами
if [ ! -d "$AGENTS_DIR" ]; then
    log_error "Директория агентов не найдена: $AGENTS_DIR"
    exit 1
fi

# Подсчет общего количества агентов
total_agents=0
orc_agents=0
work_agents=0
agents_with_description=0

# Создаем директорию для отчета
mkdir -p "$(dirname "$OUTPUT_FILE")"

# Создаем отчет
cat > "$OUTPUT_FILE" << 'EOF'
# Отчет об анализе агентов

## Сводка

EOF

# Сканируем все файлы агентов
for agent_file in "$AGENTS_DIR"/*.md; do
    if [ -f "$agent_file" ]; then
        ((total_agents++))
        agent_name=$(basename "$agent_file" .md)
        
        # Определяем тип агента
        if [[ "$agent_name" == orc_* ]]; then
            ((orc_agents++))
            agent_type="Оркестратор"
        elif [[ "$agent_name" == work_* ]]; then
            ((work_agents++))
            agent_type="Воркер"
        else
            agent_type="Неизвестный"
        fi
        
        # Извлекаем метаданные из YAML заголовка
        if head -n 50 "$agent_file" | grep -q '^---$'; then
            yaml_block=$(sed -n '1,/^---$/p' "$agent_file" | head -n -1 | sed '1d')
            
            # Извлекаем описание
            description=$(echo "$yaml_block" | grep '^description:' | sed 's/description:[[:space:]]*//' | sed 's/^"\(.*\)"$/\1/' | sed "s/^'\(.*\)'\$/\1/")
            
            if [ -n "$description" ]; then
                ((agents_with_description++))
            fi
            
            # Извлекаем цвет
            color=$(echo "$yaml_block" | grep '^color:' | sed 's/color:[[:space:]]*'//')
        fi
        
        # Ищем функциональность в теле файла
        functionality=$(grep -A 3 -E "^## (Назначение|Purpose|Functionality)" "$agent_file" | grep -v "^## " | head -n 3 | tr '\n' ' ' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        
        # Добавляем информацию об агенте в отчет
        cat >> "$OUTPUT_FILE" << EOF
### $agent_name
- **Тип**: $agent_type
- **Описание**: ${description:-"Не указано"}
- **Функциональность**: ${functionality:-"Не указана"}
- **Цвет**: ${color:-"Не указан"}

EOF
    fi
done

# Добавляем статистику в отчет
{
    echo "## Статистика"
    echo ""
    echo "- Всего агентов: $total_agents"
    echo "- Оркестраторов: $orc_agents"
    echo "- Воркеров: $work_agents"
    echo "- Агентов с описанием: $agents_with_description"
    echo "- Доля агентов с описанием: $(if [ $total_agents -gt 0 ]; then echo "scale=2; $agents_with_description * 100 / $total_agents" | bc; else echo "0"; fi)%"
    echo ""
    echo "## Рекомендации"
    echo ""
    echo "1. Убедитесь, что все агенты имеют описания в YAML заголовке"
    echo "2. Добавьте больше информации о функциональности в раздел 'Назначение'"
    echo "3. Рассмотрите возможность добавления метаданных для улучшения навигации"
} >> "$OUTPUT_FILE"

log_success "Анализ агентов завершен. Отчет сохранен в: $OUTPUT_FILE"
log_info "Проанализировано $total_agents агентов ($orc_agents оркестраторов, $work_agents воркеров)"