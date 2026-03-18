#!/bin/bash
# Скрипт автоматического обновления индекса агентов
# Назначение: Обновление файла индекса агентов на основе файлов агентов в .qwen/agents/

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

INDEX_FILE="docs/agents-index.md"
AGENTS_DIR=".qwen/agents"

log_info "Начало обновления индекса агентов"

# Проверяем, существует ли директория с агентами
if [ ! -d "$AGENTS_DIR" ]; then
    log_error "Директория агентов не найдена: $AGENTS_DIR"
    exit 1
fi

# Создаем директорию для индекса, если не существует
mkdir -p "$(dirname "$INDEX_FILE")"

# Начинаем формировать содержимое индекса
cat > "$INDEX_FILE" << 'EOF'
# Индекс агентов Qwen Orchestrator Kit

> **Назначение**: Этот файл помогает быстро находить агентов по функциональности.
> **Обновлено**: $(date)

## Структура

- [Оркестраторы](#оркестраторы)
- [Воркеры](#воркеры)
- [Поиск по функциональности](#поиск-по-функциональности)

## Оркестраторы

EOF

# Находим и добавляем оркестраторы
orc_count=0
for agent_file in "$AGENTS_DIR"/orc_*.md; do
    if [ -f "$agent_file" ]; then
        agent_name=$(basename "$agent_file" .md)
        # Извлекаем описание из YAML заголовка
        description=$(sed -n '/^---$/,/^---$/p' "$agent_file" | grep '^description:' | sed 's/description:[[:space:]]*//' | sed 's/^"\(.*\)"$/\1/' | sed "s/^'\(.*\)'$/\1/")
        
        if [ -z "$description" ]; then
            # Если описание не найдено в YAML заголовке, пробуем найти в теле файла
            description=$(head -n 20 "$agent_file" | grep -A 1 "^# " | tail -n 1 | sed 's/^# //' | sed 's/^## //')
        fi
        
        if [ -z "$description" ]; then
            description="Описание недоступно"
        fi
        
        echo "- [$agent_name](../$agent_file) - $description" >> "$INDEX_FILE"
        ((orc_count++))
    fi
done

if [ $orc_count -eq 0 ]; then
    echo "Нет доступных оркестраторов." >> "$INDEX_FILE"
fi

# Добавляем раздел воркеров
cat >> "$INDEX_FILE" << 'EOF'

## Воркеры

EOF

# Находим и добавляем воркеров
work_count=0
for agent_file in "$AGENTS_DIR"/work_*.md; do
    if [ -f "$agent_file" ]; then
        agent_name=$(basename "$agent_file" .md)
        # Извлекаем описание из YAML заголовка
        description=$(sed -n '/^---$/,/^---$/p' "$agent_file" | grep '^description:' | sed 's/description:[[:space:]]*//' | sed 's/^"\(.*\)"$/\1/' | sed "s/^'\(.*\)'\$/\1/")
        
        if [ -z "$description" ]; then
            # Если описание не найдено в YAML заголовке, пробуем найти в теле файла
            description=$(head -n 20 "$agent_file" | grep -A 1 "^# " | tail -n 1 | sed 's/^# //' | sed 's/^## //')
        fi
        
        if [ -z "$description" ]; then
            description="Описание недоступно"
        fi
        
        echo "- [$agent_name](../$agent_file) - $description" >> "$INDEX_FILE"
        ((work_count++))
    fi
done

if [ $work_count -eq 0 ]; then
    echo "Нет доступных воркеров." >> "$INDEX_FILE"
fi

# Добавляем общую статистику
cat >> "$INDEX_FILE" << EOF

## Статистика

- Всего агентов: $((orc_count + work_count))
- Оркестраторов: $orc_count
- Воркеров: $work_count

## Поиск по функциональности

Для поиска агентов по функциональности используйте поиск по файлу (Ctrl+F) или команду:

\`\`\`bash
grep -r "[ключевое_слово]" $AGENTS_DIR/
\`\`\`

EOF

log_success "Индекс агентов успешно обновлен: $INDEX_FILE"
log_info "Найдено $orc_count оркестраторов и $work_count воркеров"